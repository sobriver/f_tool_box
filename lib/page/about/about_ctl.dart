import 'package:f_tool_box/utils/base_controller.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutCtl extends BaseController {
  final version = "".obs;
  final buildNumber = "".obs;
  final appName = "".obs;

  @override
  void onReady() async {
    final info = await PackageInfo.fromPlatform();
    version.value = info.version;
    buildNumber.value = info.buildNumber;
    appName.value = info.appName;
    super.onReady();
  }
}
