import 'dart:io';
import 'package:exif/exif.dart';
import 'package:f_tool_box/utils/logger_utils.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;

import '../../utils/base_controller.dart';
import '../../utils/toast_utils.dart';

class ResetFileTimeCtl extends BaseController {
  final srcDirController = "".obs;
  final dstDirController = "".obs;

  final handlingFile = "".obs;
  final handledTotal = 0.obs;
  final progressVal = 0.0.obs;

  final allFiles = List<File>.empty().obs;

  // 是否使用exif信息检测文件信息
  final isExif = true.obs;

  void infoReset() {
    allFiles.clear();
    handlingFile.value = "";
    handledTotal.value = 0;
    progressVal.value = 0.0;
  }

  Future loadSrcFiles() async {
    infoReset();
    var srcDir = Directory(srcDirController.value);
    await for (var entity in srcDir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        allFiles.add(entity);
      }
    }
  }

  void startHandle() async {
    try {
      setBusy();
      var srcDir = Directory(srcDirController.value);
      var dstDir = Directory(dstDirController.value);
      if (!await srcDir.exists()) {
        showToast("source_dir_not_exist".tr);
        return;
      }
      if (!await dstDir.exists()) {
        showToast("target_dir_not_exist".tr);
        return;
      }
      handledTotal.value = 0;
      int total = allFiles.length;
      for (var file in allFiles) {
        var createTime = await getRealCreateTime(file);
        var dstChildDir = Directory(
          path.join(dstDir.path, createTime.year.toString()),
        );
        if (!await dstChildDir.exists()) {
          logger.i('dstChildDir not exist, create new:${dstChildDir.toString()}');
          await dstChildDir.create(recursive: true);
        }
        var dstFile = path.join(dstChildDir.path, path.basename(file.path));
        handlingFile.value = file.path;
        await file.copy(dstFile);
        handledTotal.value++;
        progressVal.value = handledTotal.value / total;
      }
      showToast("all_tasks_completed".tr);
    } catch (e) {
      logger.e("catch err:", error: e);
      setError();
    } finally {
      setDone();
    }
  }

  Future<DateTime> getRealCreateTime(File file) async {
    List<DateTime> times = [];
    // 取最早的时间吧
    var stat = await file.stat();
    times.add(stat.changed);
    times.add(stat.accessed);
    times.add(stat.modified);
    var createTime = times.reduce((a, b) => a.isBefore(b) ? a : b);
    if (!isExif.value) {
      return createTime;
    }

    var metas = await readExifFromFile(file);
    if (metas.isEmpty) {
      logger.w("exif meta empty:${file.path}");
      return createTime;
    }
    if (metas.containsKey("EXIF DateTimeOriginal")) {
      var time = metas["EXIF DateTimeOriginal"].toString();
      var dt = parseStrToDatetime(time);
      if (dt == null) {
        logger.w("exif DateTimeOriginal format invalid, file:${file.path} val:$time");
        return createTime;
      }
      return dt;
    }
    logger.w("exif DateTimeOriginal not exist:${file.path}");
    return createTime;
  }

  DateTime? parseStrToDatetime(String val) {
    // 格式为 2012:03:31 19:32:51
    String fixed = val.replaceFirst(':', '-').replaceFirst(':', '-');
    return DateTime.tryParse(fixed);
  }
}
