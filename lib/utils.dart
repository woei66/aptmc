import 'dart:io';
import 'package:flutter/material.dart';
import 'package:aptmc/myvars.dart';

Future<void> ensureDirectoryExists(String filePath) async {
  final subDir = File(filePath).parent;

  //print("[directory] ${filePath}");
  if (await !subDir.existsSync()) {
    subDir.createSync(recursive: true);
    //print("[directory] create: ${subDir} ok");
  } else {
    //print("[directory] create: ${subDir} existed");
  }
  /*if (!await subDir.exists()) {
    await subDir.create(recursive: true);
  }*/
}

Future<String> sanitizeString(String input) async {
  // instance directory name
  return input.replaceAll(RegExp(r'[^a-z0-9_]'), '_');
}

Future<void> setBottomIconColor(String name) async {
  bottomIconColor.forEach((key, value) {
    if (key == name) {
      bottomIconColor[key] = Colors.blue;
    } else {
      bottomIconColor[key] = Colors.black;
    }
  });
}
