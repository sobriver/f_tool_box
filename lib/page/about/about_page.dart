import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'about_ctl.dart';

class AboutPage extends StatelessWidget {

  final ctl = Get.put(AboutCtl());

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset('assets/images/logo.png', width: 120, height: 120),
        Text("app_name".tr, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),),
        const SizedBox(height: 10),
        Text("${'version'.tr}:${ctl.version}"),
        const SizedBox(height: 10),
        Text("Build Number:${ctl.buildNumber}"),
      ],
    );
  }

}