import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'video_downloader_ctl.dart';

class VideoDownloaderPage extends StatelessWidget {
  VideoDownloaderPage({super.key});

  final VideoDownloaderCtl ctl = Get.put(VideoDownloaderCtl());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('视频下载'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '仅下载您有权保存的公开、未加密视频。受 DRM 保护、付费或需绕过权限的内容不受支持。',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctl.urlController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: '视频页面网址',
                hintText: 'https://example.com/video',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => _DirectoryField(directory: ctl.saveDirectory.value),
                  ),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _pickDirectory,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('选择目录'),
                ),
                const SizedBox(width: 10),
                Obx(
                  () =>
                      ctl.isDownloading.value
                          ? OutlinedButton.icon(
                            onPressed: ctl.cancel,
                            icon: const Icon(Icons.stop_circle_outlined),
                            label: const Text('取消下载'),
                          )
                          : FilledButton.icon(
                            onPressed: ctl.start,
                            icon: const Icon(Icons.download),
                            label: const Text('开始下载'),
                          ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _DownloadProgress(ctl: ctl),
            const SizedBox(height: 14),
            const Text('下载日志', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Expanded(
              child: Obx(
                () => Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: ListView.builder(
                    controller: ctl.logScrollController,
                    itemCount: ctl.logLines.length,
                    itemBuilder:
                        (_, index) => Text(
                          ctl.logLines[index],
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDirectory() async {
    final directory = await FilePicker.platform.getDirectoryPath();
    if (directory != null) ctl.saveDirectory.value = directory;
  }
}

class _DirectoryField extends StatelessWidget {
  const _DirectoryField({required this.directory});

  final String directory;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: '保存目录',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.folder_outlined),
      ),
      child: Text(
        directory.isEmpty ? '未选择' : directory,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _DownloadProgress extends StatelessWidget {
  const _DownloadProgress({required this.ctl});

  final VideoDownloaderCtl ctl;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final percent =
          ctl.hasPercent.value
              ? '${(ctl.progress.value * 100).toStringAsFixed(1)}%'
              : ctl.isDownloading.value
              ? '计算中'
              : '0.0%';
      final indicatorValue =
          ctl.hasPercent.value || !ctl.isDownloading.value
              ? ctl.progress.value
              : null;
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(.72),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  ctl.status.value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(percent),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: indicatorValue,
              minHeight: 9,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 28,
              runSpacing: 6,
              children: [
                _Metric(label: '下载速度', value: ctl.speed.value),
                _Metric(label: '已下载', value: ctl.downloaded.value),
                _Metric(label: '总大小', value: ctl.total.value),
                _Metric(label: '预计剩余', value: ctl.eta.value),
              ],
            ),
            if (ctl.outputFile.value.isNotEmpty) ...[
              const SizedBox(height: 8),
              SelectableText(
                '文件：${ctl.outputFile.value}',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text('$label：$value');
  }
}
