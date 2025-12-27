import 'dart:io';

import 'package:f_tool_box/components/button_progress.dart';
import 'package:f_tool_box/page/pic_to_video/pic_to_video_ctl.dart';
import 'package:f_tool_box/utils/time_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PicToVideoPage extends StatelessWidget {

  final ctl = Get.put(PicToVideoCtl());

  @override
  Widget build(BuildContext context) {
   return Scaffold(
     appBar: AppBar(title: Text("图片转视频"), centerTitle: true,),
     body: Container(
       margin: EdgeInsets.only(left: 12, right: 12, top: 2, bottom: 30),
       child: Column(
         children: [
           Row(
             children: [
               Text("Ffmpeg文件", style: Get.textTheme.titleMedium),
               const SizedBox(width: 10),

               Obx(() => Text(ctl.ffmpegFile.value)),
               const SizedBox(width: 5),
               ElevatedButton(onPressed: _pickFfmpegFile, child: Text("选择")),
             ],
           ),

           const SizedBox(height: 8),
           Row(
             children: [
               Text("输出视频文件目录", style: Get.textTheme.titleMedium),
               const SizedBox(width: 10),

               Obx(() => Text(ctl.outputDir.value)),
               const SizedBox(width: 5),
               ElevatedButton(onPressed: _pickOutputDirectory, child: Text("选择")),
             ],
           ),

           const SizedBox(height: 8),
           Row(
             mainAxisAlignment: MainAxisAlignment.spaceBetween,
             children: [
               Row(children: [
                 OutlinedButton(
                   child: Text('选择图片目录'),
                   onPressed: _pickDirectory,
                 ),
                 const SizedBox(width: 30),
                 Row(
                   children: [
                     Text("帧率", style: Get.textTheme.labelSmall),
                     const SizedBox(width: 10),
                     SizedBox(width: 40, child: TextField(
                       controller: ctl.frameRateTextController,
                       keyboardType: TextInputType.number,
                     ),)
                   ],
                 ),

                 const SizedBox(width: 30),
                 Transform.scale(
                     scale: 0.5,
                     child: Obx(() => Switch(
                       value: ctl.childDect.value,
                       onChanged:(value) => ctl.childDect.value = value,
                     ))
                 ),
                 Text("自动识别子目录", style: Get.textTheme.labelSmall,),


                 const SizedBox(width: 30),
                 Transform.scale(
                     scale: 0.5,
                     child: Obx(() => Switch(
                       value: ctl.useNvidia.value,
                       onChanged:(value) => ctl.useNvidia.value = value,
                     ))
                 ),
                 Text("nvidia加速", style: Get.textTheme.labelSmall,),



               ],),


               ElevatedButton.icon(
                 icon: Icon(Icons.delete, color: Colors.red,),
                 label: Text('清空所有'),
                 onPressed: ctl.emptyDirs,
               ),
             ],
           ),

          Divider(),
          Expanded(child:  Obx(() => ListView.builder(
            itemCount: ctl.srcDirs.length,
            itemBuilder: (BuildContext context, int index) {
              var dirItem = ctl.srcDirs[index];
              return Card(
                child: ListTile(
                  leading: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(value: dirItem.progress/100),
                      Text("${dirItem.progress.toStringAsFixed(0)}%")
                    ],
                  ),
                  title: Text(dirItem.dir),
                  subtitle: Text("文件数: ${dirItem.fileNumber}     耗时: ${TimeUtils.formatMilliseconds(dirItem.costTime)}"),
                  trailing: IconButton(onPressed: () => ctl.removeItem(index), icon: Icon(Icons.close, color: Colors.red,)),
                ),
              );
            },
          ))),

           Container(
             alignment: Alignment.bottomCenter,
             child: Obx(() => ctl.isProcessing.value ? ProgressButtonWithText(text: "in_progress".tr) : ElevatedButton.icon(
               onPressed: ctl.start,
               label: Text('start_execution'.tr),
               icon: Icon(Icons.send),
             ))
           ),
         ],
       ),
     ),
   );
  }

  Future _pickFfmpegFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      ctl.ffmpegFile.value = result.files.single.path!;
    }
  }


  Future _pickDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      ctl.addItem(selectedDirectory);
    }
  }

  Future _pickOutputDirectory() async {
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory != null) {
      ctl.outputDir.value = selectedDirectory;
    }
  }

}