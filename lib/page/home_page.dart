import 'package:f_tool_box/page/pic_to_video/pic_to_video_page.dart';
import 'package:f_tool_box/page/pomodoro/pomodoro_page.dart';
import 'package:f_tool_box/page/video_downloader/video_downloader_page.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'about/about_page.dart';
import 'reset_file_by_time/reset_file_time_page.dart';

class HomePage extends StatelessWidget {
  final controller = Get.put(NavController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          Obx(() => NavigationRail(
            selectedIndex: controller.selectedIndex.value,
            onDestinationSelected: (index) => controller.changePage(index),
            labelType: NavigationRailLabelType.all,
            destinations: [
              NavigationRailDestination(
                  icon: Icon(Icons.file_copy, color: Colors.deepPurple,), label: Text('reset_file_by_time'.tr)),
              NavigationRailDestination(
                  icon: Icon(Icons.download_for_offline, color: Colors.redAccent,), label: Text('视频下载')),
              NavigationRailDestination(
                  icon: Icon(Icons.video_call, color: Colors.cyan,), label: Text('图片转视频')),
              NavigationRailDestination(
                  icon: Icon(Icons.alarm, color: Colors.blue,), label: Text('番茄钟')),
              NavigationRailDestination(
                  icon: Icon(Icons.info, color: Colors.orange,), label: Text('about'.tr)),
            ],
          )),
          VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: Obx(() {
              return controller.pages[controller.selectedIndex.value];
            }),
          )
        ],
      ),
    );
  }
}

class NavController extends GetxController {
  var selectedIndex = 0.obs;

  List<Widget> pages = [
    ResetFileByTimePage(),
    VideoDownloaderPage(),
    PicToVideoPage(),
    PomodoroPage(),
    AboutPage(),
  ];

  void changePage(int index) {
    selectedIndex.value = index;
  }
}
