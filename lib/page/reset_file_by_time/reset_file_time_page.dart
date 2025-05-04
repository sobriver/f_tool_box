import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../components/button_progress.dart';
import 'reset_file_time_ctl.dart';

class ResetFileByTimePage extends StatelessWidget {

  final ctl = Get.put(ResetFileTimeCtl());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("reset_file_by_time".tr),
        centerTitle: true,
      ),
      body: Container(
        margin: EdgeInsets.only(left: 12, right: 12, top: 5, bottom: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _pickSrcDirectory,
                      style: outBtnStyle,
                      child: Text('source_dir'.tr),
                    ),
                    const SizedBox(width: 10,),
                    Obx(() => Text(ctl.srcDirController.value))
                  ],
                ),
                const SizedBox(height: 10,),
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _pickDstDirectory,
                      style: outBtnStyle,
                      child: Text('target_dir'.tr),
                    ),
                    const SizedBox(width: 10,),
                    Obx(() => Text(ctl.dstDirController.value))
                  ],
                ),
                const SizedBox(height: 5,),
                Row(
                  children: [
                    Obx(() => Checkbox(
                      value: ctl.isExif.value,
                      onChanged: (bool? value) {
                        if (value != null) {
                          ctl.isExif.value = value;
                        }
                      },
                    ),),
                    Text("use_exif_metadata".tr)
                  ],
                ),
              ],
            ),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Obx(() => Text("${ctl.handledTotal}/${ctl.allFiles.length}")),
                    Obx(() => Text("${ctl.handlingFile}")),
                  ],
                ),
                const SizedBox(height: 5,),
                Obx(() => LinearProgressIndicator(value: ctl.progressVal.value, minHeight: 8, borderRadius: BorderRadius.circular(15),)),
                const SizedBox(height: 15,),
                Center(
                  child: Obx(() => ctl.isBusy() ? ProgressButtonWithText(text: "in_progress".tr) : ElevatedButton.icon(
                    onPressed: ctl.startHandle,
                    label: Text('start_execution'.tr),
                    icon: Icon(Icons.send),
                  )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future _pickSrcDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      ctl.srcDirController.value = selectedDirectory;
      ctl.loadSrcFiles();
    }
  }
  Future _pickDstDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      ctl.dstDirController.value = selectedDirectory;
    }
  }

}


const qqInputBorder = OutlineInputBorder(
  borderSide: BorderSide(color: Color(0x00FF0000)),
  // borderRadius: BorderRadius.all(Radius.circular(50))
);

var outBtnStyle = OutlinedButton.styleFrom(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8), // 设置圆角半径
  ),
);