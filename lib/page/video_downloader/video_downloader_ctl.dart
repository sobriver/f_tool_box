import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;

import '../../utils/toast_utils.dart';

/// Uses a locally installed yt-dlp executable. Keeping the extractor outside
/// the app makes site support updateable without shipping site-specific code.
class VideoDownloaderCtl extends GetxController {
  final urlController = TextEditingController();
  final saveDirectory = ''.obs;
  final isDownloading = false.obs;
  final status = '等待开始'.obs;
  final progress = 0.0.obs;
  final speed = '--'.obs;
  final downloaded = '0 B'.obs;
  final total = '未知'.obs;
  final eta = '--'.obs;
  final outputFile = ''.obs;
  final logLines = <String>[].obs;
  final hasPercent = false.obs;
  final logScrollController = ScrollController();

  Process? _process;
  StreamSubscription<String>? _stdoutSubscription;
  StreamSubscription<String>? _stderrSubscription;
  Timer? _fallbackProgressTimer;
  Directory? _activeDestination;
  DateTime? _downloadStartedAt;
  DateTime? _lastObservedAt;
  int _lastObservedBytes = 0;
  bool _receivedEngineProgress = false;
  int? _overallTotalBytes;
  bool _overallTotalEstimated = false;
  final Map<String, int> _downloadedBytesByFormat = {};
  DateTime? _lastProgressLogAt;

  Future<void> start() async {
    final inputUrl = urlController.text.trim();
    final uri = Uri.tryParse(inputUrl);
    if (uri == null ||
        !uri.hasScheme ||
        (uri.scheme != 'https' && uri.scheme != 'http') ||
        uri.host.isEmpty) {
      showToast('请输入有效的视频页面网址');
      return;
    }
    if (saveDirectory.value.isEmpty) {
      showToast('请选择保存目录');
      return;
    }

    final destination = Directory(saveDirectory.value);
    if (!await destination.exists()) {
      showToast('保存目录不存在');
      return;
    }

    final executable = await _findYtDlp();
    if (executable == null) {
      status.value = '未找到 yt-dlp';
      _addLog('请将 yt-dlp.exe 放到程序同目录，或安装并加入系统 PATH。');
      showToast('未找到 yt-dlp 下载引擎');
      return;
    }

    isDownloading.value = true;
    progress.value = 0;
    speed.value = '--';
    downloaded.value = '0 B';
    total.value = '未知';
    eta.value = '--';
    outputFile.value = '';
    hasPercent.value = false;
    _receivedEngineProgress = false;
    _overallTotalBytes = null;
    _overallTotalEstimated = false;
    _downloadedBytesByFormat.clear();
    _lastProgressLogAt = null;
    logLines.clear();
    status.value = '正在解析视频…';
    _addLog('使用下载引擎：$executable');

    const marker = '__FTB_PROGRESS__';
    const fileMarker = '__FTB_FILE__';
    const metaMarker = '__FTB_META__';
    final args = <String>[
      '--no-playlist',
      '--no-simulate',
      '--no-quiet',
      '--verbose',
      '--progress',
      '--newline',
      '--progress-delta',
      '0.5',
      '--progress-template',
      'download:${marker}%(progress._percent_str)s|%(progress._speed_str)s|%(progress.downloaded_bytes)s|%(progress.total_bytes)s|%(progress.total_bytes_estimate)s|%(progress._eta_str)s|%(progress.fragment_index)s|%(progress.fragment_count)s|%(info.format_id)s',
      '--print',
      'before_dl:${metaMarker}%(filesize|NA)s|%(filesize_approx|NA)s|%(requested_formats.:.filesize)j|%(requested_formats.:.filesize_approx)j',
      '--print',
      'after_move:${fileMarker}%(filepath)s',
      '-P',
      destination.path,
      '-o',
      '%(title).200B.%(ext)s',
      inputUrl,
    ];

    try {
      _process = await Process.start(executable, args, runInShell: false);
      status.value = '正在连接并下载…';
      _startFallbackProgressMonitor(destination);
      _stdoutSubscription = _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleOutputLine);
      _stderrSubscription = _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(_handleOutputLine);

      final exitCode = await _process!.exitCode;
      if (exitCode == 0) {
        progress.value = 1;
        hasPercent.value = true;
        status.value = '下载完成';
        speed.value = '--';
        eta.value = '--';
        _addLog('[yt-dlp] 下载完成');
      } else if (status.value != '已取消') {
        status.value = '下载失败（退出码 $exitCode）';
        _addLog('下载进程异常结束，退出码：$exitCode');
      }
    } on ProcessException catch (e) {
      status.value = '无法启动下载引擎';
      _addLog(e.message);
    } catch (e) {
      status.value = '下载出错';
      _addLog(e.toString());
    } finally {
      _fallbackProgressTimer?.cancel();
      _fallbackProgressTimer = null;
      _activeDestination = null;
      await _stdoutSubscription?.cancel();
      await _stderrSubscription?.cancel();
      _stdoutSubscription = null;
      _stderrSubscription = null;
      _process = null;
      isDownloading.value = false;
    }
  }

  void cancel() {
    final process = _process;
    if (process == null) return;
    status.value = '已取消';
    _addLog('正在取消下载…');
    process.kill(ProcessSignal.sigterm);
  }

  Future<String?> _findYtDlp() async {
    final candidates = <String>[];
    if (Platform.isWindows) {
      candidates.add(
        path.join(path.dirname(Platform.resolvedExecutable), 'yt-dlp.exe'),
      );
      candidates.add('yt-dlp.exe');
    } else {
      candidates.add(
        path.join(path.dirname(Platform.resolvedExecutable), 'yt-dlp'),
      );
      candidates.add('yt-dlp');
    }
    for (final candidate in candidates) {
      try {
        final result = await Process.run(candidate, const [
          '--version',
        ], runInShell: false);
        if (result.exitCode == 0) return candidate;
      } on ProcessException {
        // Try the next known location.
      }
    }
    return null;
  }

  void _handleOutputLine(String line) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return;
    const progressMarker = '__FTB_PROGRESS__';
    const fileMarker = '__FTB_FILE__';
    const metaMarker = '__FTB_META__';
    final metaIndex = trimmed.indexOf(metaMarker);
    if (metaIndex >= 0) {
      _handleDownloadMetadata(trimmed.substring(metaIndex + metaMarker.length));
      return;
    }
    final markerIndex = trimmed.indexOf(progressMarker);
    if (markerIndex >= 0) {
      final rawProgress = trimmed.substring(
        markerIndex + progressMarker.length,
      );
      if (!_updateProgress(rawProgress)) {
        _addLog('无法解析下载进度：$rawProgress');
      }
      return;
    }
    final fileMarkerIndex = trimmed.indexOf(fileMarker);
    if (fileMarkerIndex >= 0) {
      outputFile.value = trimmed.substring(fileMarkerIndex + fileMarker.length);
      _addLog('[yt-dlp] 已保存：${outputFile.value}');
      return;
    }
    if (_parseStandardProgress(trimmed)) return;
    if (trimmed.contains('Merging formats') || trimmed.contains('Fixing')) {
      status.value = '正在合并音视频…';
    } else if (trimmed.contains('ERROR:')) {
      status.value = '下载失败';
    }
    _addLog('[yt-dlp] $trimmed');
  }

  bool _updateProgress(String raw) {
    final parts = _stripAnsi(raw).split('|');
    if (parts.length < 5) return false;
    final percentText = parts[0].replaceAll(RegExp(r'[^0-9.]'), '');
    final percent = double.tryParse(percentText);
    final currentDownloaded = int.tryParse(parts[2].trim()) ?? 0;
    final exactTotal = int.tryParse(parts[3].trim());
    final estimatedTotal =
        parts.length >= 6 ? int.tryParse(parts[4].trim()) : null;
    final etaIndex = parts.length >= 6 ? 5 : 4;
    final fragmentIndex = parts.length >= 7 ? parts[6].trim() : '';
    final fragmentCount = parts.length >= 8 ? parts[7].trim() : '';
    final formatId =
        parts.length >= 9 && parts[8].trim().isNotEmpty
            ? parts[8].trim()
            : 'default';

    speed.value = parts[1].trim().isEmpty ? '--' : parts[1].trim();
    _downloadedBytesByFormat[formatId] = currentDownloaded;
    final overallDownloaded = _downloadedBytesByFormat.values.fold<int>(
      0,
      (sum, bytes) => sum + bytes,
    );
    downloaded.value = _formatBytes(overallDownloaded);

    final knownOverallTotal = _overallTotalBytes;
    if (knownOverallTotal != null && knownOverallTotal > 0) {
      progress.value = (overallDownloaded / knownOverallTotal).clamp(0.0, 1.0);
      hasPercent.value = true;
      total.value =
          '${_overallTotalEstimated ? '约 ' : ''}${_formatBytes(knownOverallTotal)}';
    } else {
      final currentTotal =
          exactTotal != null && exactTotal > 0 ? exactTotal : estimatedTotal;
      if (currentTotal != null && currentTotal > 0) {
        total.value =
            '${exactTotal == null || exactTotal <= 0 ? '约 ' : ''}${_formatBytes(currentTotal)}';
      }
      if (percent != null) {
        progress.value = (percent / 100).clamp(0.0, 1.0);
        hasPercent.value = true;
      }
    }

    final etaText = parts[etaIndex].trim();
    eta.value = etaText.isEmpty || etaText == 'NA' ? '--' : etaText;
    status.value = progress.value >= 1 ? '正在收尾…' : '下载中';
    _receivedEngineProgress = true;
    _logProgressSnapshot(
      fragmentIndex: fragmentIndex,
      fragmentCount: fragmentCount,
    );
    return true;
  }

  void _handleDownloadMetadata(String raw) {
    final parts = _stripAnsi(raw).split('|');
    if (parts.length < 4) {
      _addLog('[yt-dlp] 无法解析视频大小信息：$raw');
      return;
    }

    final directExact = int.tryParse(parts[0].trim());
    final directEstimate = int.tryParse(parts[1].trim());
    final requestedExact = _parseNumberList(parts[2]);
    final requestedEstimate = _parseNumberList(parts[3]);

    var sum = 0;
    var isEstimate = false;
    final formatCount =
        requestedExact.length > requestedEstimate.length
            ? requestedExact.length
            : requestedEstimate.length;
    for (var index = 0; index < formatCount; index++) {
      final exact =
          index < requestedExact.length ? requestedExact[index] : null;
      final estimate =
          index < requestedEstimate.length ? requestedEstimate[index] : null;
      if (exact != null && exact > 0) {
        sum += exact;
      } else if (estimate != null && estimate > 0) {
        sum += estimate;
        isEstimate = true;
      }
    }

    if (sum <= 0 && directExact != null && directExact > 0) {
      sum = directExact;
    } else if (sum <= 0 && directEstimate != null && directEstimate > 0) {
      sum = directEstimate;
      isEstimate = true;
    }

    if (sum > 0) {
      _overallTotalBytes = sum;
      _overallTotalEstimated = isEstimate;
      total.value = '${isEstimate ? '约 ' : ''}${_formatBytes(sum)}';
      _addLog('[yt-dlp] 已获取${isEstimate ? '估算' : '精确'}总大小：${total.value}');
    } else {
      _addLog('[yt-dlp] 服务器未提供视频总大小，将使用实时下载进度');
    }
  }

  List<int?> _parseNumberList(String raw) {
    try {
      final decoded = jsonDecode(raw.trim());
      if (decoded is! List) return const [];
      return decoded.map<int?>((value) {
        if (value is num) return value.toInt();
        return int.tryParse(value?.toString() ?? '');
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  bool _parseStandardProgress(String line) {
    final match = RegExp(
      r'(\d+(?:\.\d+)?)%\s+of\s+(.+?)\s+at\s+(.+?)(?:\s+ETA\s+(\S+))?$',
    ).firstMatch(_stripAnsi(line));
    if (match == null) return false;
    final percent = double.tryParse(match.group(1)!);
    if (percent == null) return false;
    progress.value = (percent / 100).clamp(0.0, 1.0);
    hasPercent.value = true;
    total.value = match.group(2)!.trim();
    speed.value = match.group(3)!.trim();
    eta.value = match.group(4) == null ? '--' : '${match.group(4)} 秒';
    status.value = progress.value >= 1 ? '正在收尾…' : '下载中';
    _receivedEngineProgress = true;
    _logProgressSnapshot();
    return true;
  }

  void _logProgressSnapshot({
    String fragmentIndex = '',
    String fragmentCount = '',
  }) {
    final now = DateTime.now();
    final lastLogAt = _lastProgressLogAt;
    if (lastLogAt != null &&
        now.difference(lastLogAt) < const Duration(seconds: 1) &&
        progress.value < 1) {
      return;
    }
    _lastProgressLogAt = now;
    final percentText =
        hasPercent.value
            ? '${(progress.value * 100).toStringAsFixed(1)}%'
            : '进度未知';
    final fragmentText =
        fragmentIndex.isNotEmpty &&
                fragmentIndex != 'NA' &&
                fragmentCount.isNotEmpty &&
                fragmentCount != 'NA'
            ? ' | 分片 $fragmentIndex/$fragmentCount'
            : '';
    _addLog(
      '[yt-dlp][download] $percentText | ${downloaded.value}/${total.value} | ${speed.value} | ETA ${eta.value}$fragmentText',
    );
  }

  void _startFallbackProgressMonitor(Directory destination) {
    _fallbackProgressTimer?.cancel();
    _activeDestination = destination;
    _downloadStartedAt = DateTime.now();
    _lastObservedAt = null;
    _lastObservedBytes = 0;
    _fallbackProgressTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _observeOutputFiles();
    });
  }

  void _observeOutputFiles() {
    if (_receivedEngineProgress || !isDownloading.value) return;
    final destination = _activeDestination;
    final startedAt = _downloadStartedAt;
    if (destination == null || startedAt == null) return;
    try {
      final bytes = destination
          .listSync()
          .whereType<File>()
          .where(
            (file) => file.statSync().modified.isAfter(
              startedAt.subtract(const Duration(seconds: 2)),
            ),
          )
          .fold<int>(0, (sum, file) => sum + file.lengthSync());
      if (bytes <= 0) return;
      final now = DateTime.now();
      final previousTime = _lastObservedAt;
      if (previousTime != null && bytes >= _lastObservedBytes) {
        final elapsed = now.difference(previousTime).inMilliseconds / 1000;
        if (elapsed > 0) {
          speed.value =
              '${_formatBytes(((bytes - _lastObservedBytes) / elapsed).round())}/s';
        }
      }
      downloaded.value = _formatBytes(bytes);
      status.value = '下载中（正在获取视频大小…）';
      _lastObservedBytes = bytes;
      _lastObservedAt = now;
      _logProgressSnapshot();
    } catch (_) {
      // The engine's own progress output remains the primary source.
    }
  }

  String _stripAnsi(String value) =>
      value.replaceAll(RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'), '');

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    const units = ['KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var unit = -1;
    do {
      value /= 1024;
      unit++;
    } while (value >= 1024 && unit < units.length - 1);
    return '${value.toStringAsFixed(value >= 100 ? 0 : 1)} ${units[unit]}';
  }

  void _addLog(String value) {
    logLines.add(value);
    if (logLines.length > 500) logLines.removeRange(0, logLines.length - 500);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!logScrollController.hasClients) return;
      logScrollController.animateTo(
        logScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void onClose() {
    _fallbackProgressTimer?.cancel();
    _process?.kill(ProcessSignal.sigterm);
    logScrollController.dispose();
    urlController.dispose();
    super.onClose();
  }
}
