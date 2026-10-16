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
    debugShowCheckedModeBanner: false,
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
    theme: ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5B2DEE)),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1E2034),
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 19, fontWeight: FontWeight.w700, color: Color(0xFF1E2034)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFAFAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE1E3EA))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFE1E3EA))),
      ),
    ),
  ));
}


