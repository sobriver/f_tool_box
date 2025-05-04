import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

void showToast(String message) {
  BotToast.showText(text: message, align: Alignment.center);
}