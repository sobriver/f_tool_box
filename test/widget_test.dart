// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'dart:io';

void main() async {
  await compareDirectory();
  // await a();
}


Future a() async {
  File f = File(r'D:\tmp\src\2015\IMG_20150913_112424.jpg');
  var s = await f.stat();
  print('change:${s.changed} ${s.modified} ${s.accessed}');
}


Future compareDirectory() async {
  // 设置两个文件夹路径
  final dir1 = Directory(r'D:\tmp\src\2016');
  final dir2 = Directory(r'D:\tmp\dst\2016');

  if (!await dir1.exists() || !await dir2.exists()) {
    print('其中一个目录不存在');
    return;
  }

  // 获取两个文件夹中的文件名集合
  final files1 = await _listFileNames(dir1);
  final files2 = await _listFileNames(dir2);

  // 找出只在 folder1 存在的文件
  final onlyInDir1 = files1.difference(files2);
  // 找出只在 folder2 存在的文件
  final onlyInDir2 = files2.difference(files1);

  print('只在 ${dir1.path} 存在的文件:');
  onlyInDir1.forEach(print);

  print('\n只在 ${dir2.path} 存在的文件:');
  onlyInDir2.forEach(print);
}

// 辅助函数：列出文件夹中的所有文件名（不含路径）
Future<Set<String>> _listFileNames(Directory dir) async {
  final fileNames = <String>{};
  await for (final entity in dir.list(recursive: false, followLinks: false)) {
    if (entity is File) {
      fileNames.add(entity.uri.pathSegments.last);
    }
  }
  return fileNames;
}
