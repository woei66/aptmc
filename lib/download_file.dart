import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

class DownloadFile {
  static Future<void> checkFile(
      String filePath, int expectedSize, String expectedSha1) async {
    final file = File(filePath);

    // check if the file is exist?
    if (!await file.exists()) {
      print('Error: File does not exist.');
      return;
    }

    // check file size
    final fileSize = await file.length();
    if (fileSize != expectedSize) {
      print(
          'Error: File size does not match. Expected $expectedSize bytes, got $fileSize bytes.');
      return;
    }

    // calculate SHA-1 of the file
    final sha1Hash = await computeSha1(file);
    if (sha1Hash != expectedSha1) {
      print(
          'Error: SHA-1 hash does not match. Expected $expectedSha1, got $sha1Hash.');
      return;
    }

    print('File verification succeeded: Size and SHA-1 hash match.');
  }

  static Future<String> computeSha1(File file) async {
    final bytes = await file.readAsBytes();
    final digest = sha1.convert(bytes);
    return digest.toString();
  }

// url : the url to be downloaded
// filename : the local full path and filename to store
// expectedSize: the expected file size
// expectedSha1: the expected sha1 of the
  static Future<Uint8List> download(String url, String filename) async {
    File file = File(filename);
    final request = await HttpClient().getUrl(Uri.parse(url));
    final response = await request.close();

    if (response.statusCode == 200) {
      final bytes = await consolidateHttpClientResponseBytes(response);
      await file.writeAsBytes(bytes);
      print("Download file is saved: ${filename}");
      return bytes;
    } else {
      throw Exception("Downloaded failed, error = ${response.statusCode}");
    }
  }
}
