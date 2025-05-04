import 'package:bot_toast/bot_toast.dart';
import 'package:f_tool_box/utils/logger_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'dart:ui' as ui;

import 'intl/intl_dict.dart';
import 'page/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await logInit();
  runApp(GetMaterialApp(
    home: HomePage(),
    builder: BotToastInit(),
    navigatorObservers: [BotToastNavigatorObserver()],
    translations: Messages(),
    locale: ui.PlatformDispatcher.instance.locale,
    fallbackLocale: Locale('en', 'US'),
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: const [
      Locale('zh', 'CN'),
      Locale('en', 'US')
    ],
  ));
}


