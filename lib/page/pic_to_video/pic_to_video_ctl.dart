
import 'dart:io';

import 'package:f_tool_box/utils/base_controller.dart';
import 'package:f_tool_box/utils/ffmpeg_utils.dart';
import 'package:f_tool_box/utils/toast_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;

class PicToVideoCtl extends BaseController {

  final frameRateTextController = TextEditingController(text: "30");
  final isProcessing = false.obs;

  final ffmpegFile = "".obs;

  // 目标文件夹
  final srcDirs = List<DirItem>.empty().obs;
  // 是否自动识别子目录为一个项目
  final childDect = true.obs;
  // 输出文件夹
  final outputDir = "".obs;
  final useNvidia = true.obs;


  @override
  void onReady() {
    super.onReady();
  }


  void addItem(String dir) {
    List<String> dirs = [dir];
    var directory = Directory(dir);
    if (childDect.value) {
      List<String> subDirs = directory
          .listSync()
          .whereType<Directory>()
          .map((t) => t.path)
          .toList();
      dirs.addAllIf(subDirs.isNotEmpty, subDirs);
    }
    for (var d in dirs) {
      int fileNum = countImageFiles(d);
      if (fileNum == 0) {
        continue;
      }
      DirItem dirItem = DirItem(dir: d, progress: 0, fileNumber: fileNum, costTime: 0);

      int index = srcDirs.indexWhere((t) => t.dir == d);
      if (index == -1) {
          srcDirs.add(dirItem);
      } else {
          srcDirs[index] = dirItem;
      }
    }


  }

  Future emptyDirs() async {
    srcDirs.clear();
  }

  int countImageFiles(String path) {
    Directory directory = Directory(path);
    try {
      return directory
          .listSync()
          .whereType<File>()
          .where((file) {
        String ext = file.path.toLowerCase();
        return ext.endsWith('.jpg') ||
            ext.endsWith('.jpeg') ||
            ext.endsWith('.png') ||
            ext.endsWith('.gif') ||
            ext.endsWith('.bmp') ||
            ext.endsWith('.webp');
      }).length;
    } catch (e) {
      print('错误: $e');
      return 0;
    }
  }

  Future removeItem(int index) async {
    srcDirs.removeAt(index);
  }

  Future start() async {
    try {
      isProcessing.value = true;
      if (ffmpegFile.value.isEmpty) {
        showToast("ffmpeg文件未指定");
        return;
      }

      if (outputDir.value.isEmpty) {
            showToast("输出目录未指定");
            return;
          }
      if (srcDirs.isEmpty) {
            showToast("目录未指定");
            return;
          }
      int frameRate = int.tryParse(frameRateTextController.text) ?? 30;
      if (frameRate <= 0 || frameRate > 120) {
            showToast('请输入有效的帧率 (1-120)');
            return;
          }

      for (int i = 0; i < srcDirs.length; i++) {
            var dirItem = srcDirs[i];
            String outDirName = path.basename(dirItem.dir);
            String outFile = path.join(outputDir.value, "$outDirName.mp4");
            int startTime = DateTime.now().millisecondsSinceEpoch;
            bool success = await FFmpegHelper.generateVideo(
              ffmpegPath: ffmpegFile.value,
              inputDir: dirItem.dir,
              outputPath: outFile,
              frameRate: frameRate,
              useNvidiaGpu: useNvidia.value,
              onProgress: (double progress) {
                dirItem.progress = progress;
                srcDirs[i] = dirItem;
              }
            );
            var tmp = srcDirs[i];
            tmp.costTime = DateTime.now().millisecondsSinceEpoch - startTime;
            srcDirs[i] = tmp;
          }
    } finally {
      isProcessing.value = false;
    }
  }
}


class DirItem {
  String dir;
  double progress; // 处理进度
  int fileNumber;
  int costTime; // 毫秒

  DirItem({
    required this.dir,
    required this.progress,
    required this.fileNumber,
    required this.costTime
  });
}