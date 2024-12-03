import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

void createDirectoryIfNotExists(String filePath) {
  final directory = Directory(filePath).parent;

  if (!directory.existsSync()) {
    print('Directory does not exist. Creating: ${directory.path}');
    directory.createSync(recursive: true);
  }
}

// the application data directory
Future<String> getAppDataPath(String appName) async {
  final directory = await getApplicationSupportDirectory();
  return '${directory.path}/$appName';
}
