import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;
import 'package:flutter/services.dart' show rootBundle;

class FFmpegHelper {

  // 生成视频
  static Future<bool> generateVideo({
    required String ffmpegPath,
    required String inputDir,
    required String outputPath,
    required int frameRate,
    required bool useNvidiaGpu, // 是否使用nvidia加速
    Function(String output)? onLog,
    Function(double progress)? onProgress,
  }) async {

    try {
      // 获取所有图片文件
      Directory dir = Directory(inputDir);
      List<FileSystemEntity> files = dir
          .listSync()
          .where((file) {
        String filePath = file.path.toLowerCase();
        return filePath.endsWith('.jpg') ||
            filePath.endsWith('.jpeg') ||
            filePath.endsWith('.png') ||
            filePath.endsWith('.gif') ||
            filePath.endsWith('.gif') ||
            filePath.endsWith('.webp');
      })
          .toList();

      if (files.isEmpty) {
        print('目录中没有图片文件');
        return false;
      }

      // 排序
      files.sort((a, b) => a.path.compareTo(b.path));
      int totalFrames = files.length;
      print('找到 $totalFrames 个图片文件');

      // 创建临时文件列表
      String tempDir = Directory.systemTemp.path;
      String listFile = path.join(
          tempDir,
          'ffmpeg_list_${DateTime.now().millisecondsSinceEpoch}.txt'
      );

      File file = File(listFile);
      StringBuffer buffer = StringBuffer();

      double duration = 1.0 / frameRate;
      for (var imageFile in files) {
        // 转换为 Unix 风格路径
        String normalizedPath = imageFile.path.replaceAll('\\', '/');
        buffer.writeln("file '$normalizedPath'");
        buffer.writeln("duration $duration");
      }
      String lastPath = files.last.path.replaceAll('\\', '/');
      buffer.writeln("file '$lastPath'");

      await file.writeAsString(buffer.toString());

      // 构建命令参数
      List<String> arguments = [];
      if (useNvidiaGpu) {
        arguments = [
          '-f', 'concat',
          '-safe', '0',
          '-i', listFile,
          '-c:v', 'h264_nvenc',
          '-pix_fmt', 'yuv420p',
          '-r', frameRate.toString(),
          '-cq', '23',
          '-preset', 'p4',
          '-y',
          outputPath,
        ];
      } else {
        arguments = [
          '-f', 'concat',
          '-safe', '0',
          '-i', listFile,
          '-c:v', 'libx264',
          '-pix_fmt', 'yuv420p',
          '-r', frameRate.toString(),
          '-crf', '23',
          '-preset', 'medium',
          '-y',
          outputPath,
        ];
      }


      print('执行命令: $ffmpegPath ${arguments.join(" ")}');
      onLog?.call('开始生成视频...');

      // 执行 FFmpeg
      Process process = await Process.start(ffmpegPath!, arguments);

      // 监听输出 (FFmpeg 的进度信息在 stderr)
      int processedFrames = 0;

      process.stderr
          .transform(utf8.decoder)
          .transform(LineSplitter())
          .listen((line) {
        print(line);
        onLog?.call(line);

        // 解析进度: frame=  123 fps= 30 q=28.0 size=    1024kB time=00:00:04.10 bitrate=2048.0kbits/s speed=1.0x
        if (line.contains('frame=')) {
          try {
            // 提取 frame 数字
            RegExp frameRegex = RegExp(r'frame=\s*(\d+)');
            Match? match = frameRegex.firstMatch(line);
            if (match != null) {
              processedFrames = int.parse(match.group(1)!);
              double progress = (processedFrames / totalFrames) * 100;
              onProgress?.call(progress.clamp(0, 100));
            }
          } catch (e) {
            // 忽略解析错误
            print(e);
          }
        }
      });

      // stdout 通常没有太多输出
      process.stdout
          .transform(utf8.decoder)
          .transform(LineSplitter())
          .listen((line) {
        print(line);
      });

      // 等待完成
      int exitCode = await process.exitCode;

      // 清理临时文件
      try {
        await file.delete();
      } catch (e) {
        print('清理临时文件失败: $e');
      }

      if (exitCode == 0) {
        print('视频生成成功: $outputPath');
        onProgress?.call(100);
        onLog?.call('视频生成成功!');
        return true;
      } else {
        print('FFmpeg 执行失败，退出码: $exitCode');
        onLog?.call('视频生成失败，退出码: $exitCode');
        return false;
      }
    } catch (e) {
      print('生成视频时出错: $e');
      onLog?.call('错误: $e');
      return false;
    }
  }
}