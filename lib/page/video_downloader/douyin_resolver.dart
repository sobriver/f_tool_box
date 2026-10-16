import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class DouyinResolveException implements Exception {
  DouyinResolveException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DouyinVideo {
  DouyinVideo({
    required this.id,
    required this.title,
    required this.url,
    required this.width,
    required this.height,
    required this.isH265,
    required this.size,
  });

  final String id;
  final String title;
  final String url;
  final int width;
  final int height;
  final bool isH265;
  final int size;
}

/// yt-dlp's Douyin extractor calls the detail API without the request
/// signature Douyin now requires, so it fails even with fresh cookies. Here a
/// hidden WebView opens the video page anonymously and issues the same request
/// from inside the page, where Douyin's own security SDK signs it. The
/// resulting CDN address only needs the Referer and User-Agent below.
class DouyinResolver {
  static const userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/140.0.0.0 Safari/537.36 Edg/140.0.0.0';
  static const referer = 'https://www.douyin.com/';

  static Future<WebViewEnvironment?>? _environment;

  static bool get isSupportedPlatform => Platform.isWindows || Platform.isMacOS;

  static bool isDouyinUrl(Uri uri) {
    final host = uri.host.toLowerCase();
    return host == 'douyin.com' ||
        host.endsWith('.douyin.com') ||
        host.endsWith('.iesdouyin.com');
  }

  /// Picks the first link out of a pasted share text such as
  /// "7.43 复制打开抖音，看看【xx的作品】... https://v.douyin.com/abc/ ...".
  static String? extractUrl(String text) {
    final match = RegExp(
      r'https?://[^\s，。！？、；“”‘’"《》<>（）()]+',
    ).firstMatch(text);
    return match?.group(0);
  }

  static Future<String> resolveVideoId(
    Uri uri, {
    void Function(String message)? onLog,
  }) async {
    final directId = _videoIdFrom(uri);
    if (directId != null) return directId;

    final client = HttpClient()..userAgent = userAgent;
    try {
      var current = uri;
      for (var hop = 0; hop < 5; hop++) {
        final request = await client.getUrl(current);
        request.followRedirects = false;
        final response = await request.close();
        await response.drain<void>();
        final location = response.headers.value(HttpHeaders.locationHeader);
        if (location == null) break;
        current = current.resolve(location);
        onLog?.call('短链跳转：${current.origin}${current.path}');
        final id = _videoIdFrom(current);
        if (id != null) return id;
      }
    } on Exception catch (e) {
      throw DouyinResolveException('无法打开分享链接：$e');
    } finally {
      client.close(force: true);
    }
    throw DouyinResolveException('没有从链接中找到抖音作品 ID');
  }

  static String? _videoIdFrom(Uri uri) {
    final modalId = uri.queryParameters['modal_id'];
    if (modalId != null && RegExp(r'^\d+$').hasMatch(modalId)) return modalId;
    final match = RegExp(
      r'/(?:share/)?(?:video|note|slides)/(\d+)',
    ).firstMatch(uri.path);
    return match?.group(1);
  }

  static Future<DouyinVideo> resolve(
    String videoId, {
    void Function(String message)? onLog,
    bool Function()? isCancelled,
  }) async {
    if (!isSupportedPlatform) {
      throw DouyinResolveException('当前系统暂不支持抖音解析（需要 Windows 或 macOS）');
    }
    final environment = await _getEnvironment();

    final loaded = Completer<void>();
    final webView = HeadlessInAppWebView(
      webViewEnvironment: environment,
      initialUrlRequest: URLRequest(
        url: WebUri('https://www.douyin.com/video/$videoId'),
      ),
      initialSettings: InAppWebViewSettings(
        userAgent: userAgent,
        mediaPlaybackRequiresUserGesture: true,
      ),
      onLoadStop: (_, __) {
        if (!loaded.isCompleted) loaded.complete();
      },
      onReceivedError: (_, request, error) {
        if (request.isForMainFrame == true && !loaded.isCompleted) {
          loaded.completeError(
            DouyinResolveException('打开抖音页面失败：${error.description}'),
          );
        }
      },
    );

    try {
      onLog?.call('正在后台打开抖音页面（无需登录）…');
      await webView.run();
      await loaded.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw DouyinResolveException('打开抖音页面超时'),
      );

      // The security SDK that signs API requests initialises a moment after
      // the page finishes loading, so early attempts may come back empty.
      for (var attempt = 1; attempt <= 8; attempt++) {
        if (isCancelled?.call() == true) {
          throw DouyinResolveException('已取消');
        }
        await Future<void>.delayed(const Duration(seconds: 2));
        final controller = webView.webViewController;
        if (controller == null) break;
        final result = await controller.callAsyncJavaScript(
          functionBody: _detailScript,
          arguments: {'id': videoId},
        );
        if (result?.error != null) {
          onLog?.call('第 $attempt 次获取作品信息出错：${result!.error}');
          continue;
        }
        final response = _parseDetail(result?.value);
        if (response.unavailableReason != null) {
          throw DouyinResolveException(response.unavailableReason!);
        }
        final detail = response.detail;
        if (detail == null) {
          onLog?.call('第 $attempt 次获取作品信息未成功，稍后重试…');
          continue;
        }
        return _pickVideo(videoId, detail);
      }
      throw DouyinResolveException('多次尝试后仍无法获取作品信息，请稍后重试');
    } finally {
      await webView.dispose();
    }
  }

  static const _detailScript = '''
const params = new URLSearchParams({
  device_platform: 'webapp',
  aid: '6383',
  channel: 'channel_pc_web',
  aweme_id: id,
  pc_client_type: '1',
  version_code: '190500',
  version_name: '19.5.0',
});
const response = await fetch('/aweme/v1/web/aweme/detail/?' + params, {
  credentials: 'include',
});
return JSON.stringify({ status: response.status, body: await response.text() });
''';

  /// An empty or non-JSON body means the signing SDK was not ready yet and the
  /// request is worth retrying; a `filter_detail` means Douyin has answered
  /// that the work is deleted or private, so retrying cannot help.
  static ({Map<String, dynamic>? detail, String? unavailableReason})
  _parseDetail(dynamic raw) {
    const retry = (detail: null, unavailableReason: null);
    if (raw is! String) return retry;
    try {
      final wrapper = jsonDecode(raw) as Map<String, dynamic>;
      final body = wrapper['body'] as String? ?? '';
      if (body.isEmpty) return retry;
      final json = jsonDecode(body) as Map<String, dynamic>;
      final detail = json['aweme_detail'];
      if (detail is Map<String, dynamic>) {
        return (detail: detail, unavailableReason: null);
      }
      final filter = json['filter_detail'];
      if (filter is Map<String, dynamic>) {
        final message =
            filter['detail_msg'] ?? filter['notice'] ?? filter['filter_reason'];
        return (
          detail: null,
          unavailableReason: '作品无法获取：${message ?? '已删除或设为私密'}',
        );
      }
      return retry;
    } catch (_) {
      return retry;
    }
  }

  /// Prefers complete mp4 files (the dash entries carry no audio), then H.264
  /// for playback compatibility, then the highest resolution and bitrate.
  static DouyinVideo _pickVideo(String videoId, Map<String, dynamic> detail) {
    final video = detail['video'];
    final images = detail['images'];
    if (images is List && images.isNotEmpty) {
      throw DouyinResolveException('这是图文作品，暂不支持下载');
    }
    if (video is! Map<String, dynamic>) {
      throw DouyinResolveException('作品中没有找到视频');
    }

    final candidates = <DouyinVideo>[];
    final title = _titleFrom(detail['desc'], videoId);
    for (final rate in (video['bit_rate'] as List? ?? const [])) {
      if (rate is! Map<String, dynamic>) continue;
      final format = rate['format'];
      if (format != null && format != 'mp4') continue;
      final candidate = _candidateFrom(
        videoId,
        title,
        rate['play_addr'],
        isH265: rate['is_h265'] == 1,
      );
      if (candidate != null) candidates.add(candidate);
    }
    if (candidates.isEmpty) {
      final fallback = _candidateFrom(
        videoId,
        title,
        video['play_addr'],
        isH265: false,
      );
      if (fallback != null) return fallback;
      throw DouyinResolveException('没有找到可下载的视频地址');
    }

    candidates.sort((a, b) {
      if (a.isH265 != b.isH265) return a.isH265 ? 1 : -1;
      final pixels = (b.width * b.height).compareTo(a.width * a.height);
      if (pixels != 0) return pixels;
      return b.size.compareTo(a.size);
    });
    return candidates.first;
  }

  static DouyinVideo? _candidateFrom(
    String videoId,
    String title,
    dynamic playAddr, {
    required bool isH265,
  }) {
    if (playAddr is! Map<String, dynamic>) return null;
    final urls = (playAddr['url_list'] as List? ?? const [])
        .whereType<String>()
        .where((url) => url.startsWith('http'))
        .toList();
    if (urls.isEmpty) return null;
    return DouyinVideo(
      id: videoId,
      title: title,
      url: urls.first,
      width: (playAddr['width'] as num?)?.toInt() ?? 0,
      height: (playAddr['height'] as num?)?.toInt() ?? 0,
      isH265: isH265,
      size: (playAddr['data_size'] as num?)?.toInt() ?? 0,
    );
  }

  static String _titleFrom(dynamic desc, String videoId) {
    final cleaned = (desc is String ? desc : '')
        .replaceAll(RegExp(r'[\\/:*?"<>|\r\n\t]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (cleaned.isEmpty) return 'douyin_$videoId';
    final short = cleaned.length > 80 ? cleaned.substring(0, 80) : cleaned;
    return '${short.trim()}_$videoId';
  }

  static Future<WebViewEnvironment?> _getEnvironment() {
    return _environment ??= _createEnvironment();
  }

  static Future<WebViewEnvironment?> _createEnvironment() async {
    if (!Platform.isWindows) return null;
    final version = await WebViewEnvironment.getAvailableVersion();
    if (version == null) {
      _environment = null;
      throw DouyinResolveException(
        '未检测到 Microsoft Edge WebView2 运行时，请先安装后再试',
      );
    }
    // WebView2 defaults to a folder next to the exe, which is read-only when
    // the app is installed under Program Files.
    final supportDir = await getApplicationSupportDirectory();
    return WebViewEnvironment.create(
      settings: WebViewEnvironmentSettings(
        userDataFolder: path.join(supportDir.path, 'webview2'),
      ),
    );
  }
}
