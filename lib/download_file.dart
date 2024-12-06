import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'utils.dart';
import 'myvars.dart';
import 'dart:async';
import 'dart:typed_data';
import 'dart:async';
import 'dart:collection';

class DownloadFile {
  final int maxConcurrentRequests;
  int _currentActiveRequests = 0;
  final Queue<Completer<void>> _requestQueue = Queue<Completer<void>>();

  DownloadFile(this.maxConcurrentRequests);

// 等待可用的請求槽位
  Future<void> _waitForAvailableSlot() async {
    if (_currentActiveRequests < maxConcurrentRequests) {
      _currentActiveRequests++;
      return;
    }

    final completer = Completer<void>();
    _requestQueue.add(completer);
    await completer.future;
    _currentActiveRequests++;
  }

  // 釋放一個請求槽位
  void _releaseSlot() {
    _currentActiveRequests--;

    if (_requestQueue.isNotEmpty) {
      final completer = _requestQueue.removeFirst();
      completer.complete();
    }
  }

  // url : the url to be downloaded
  // filename : the local full path and filename to store
  Future<void> fetch(String url, String filename) async {
    if (await File(filename).exists()) {
      //print('[debug] ${filename} exists');
      return;
    }

    await _waitForAvailableSlot();

    print('[debug] downloader fetch ${url}');

    try {
      print('[debug] check file ${filename}');
      await ensureDirectoryExists(filename);
      print('[debug] send http request ${url}');

      final request = await HttpClient().getUrl(Uri.parse(url));
      //request.headers.add(HttpHeaders.userAgentHeader, "Dart/2.0");
      final response = await request.close();

      if (response.statusCode == 200) {
        //print('[debug] response =200');
        File file = File(filename);
        final bytes = await consolidateHttpClientResponseBytes(response);
        await file.writeAsBytes(bytes);
        print("[debug] Download file is saved: ${filename}");
        return;
      } else {
        print("[error] Downloaded failed, error = ${response.statusCode}");
        throw Exception("Downloaded failed, error = ${response.statusCode}");
      }
    } catch (e, stackTrace) {
      print('[exception] ${e}');
      print(stackTrace);
      throw Exception(e);
    } finally {
      // 釋放請求槽位
      _releaseSlot();
    }
  }

  Future<void> checkFile(
      String filePath, int expectedSize, String expectedSha1) async {
    final file = File(filePath);
    try {
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
            'Error: SHA1 hash does not match. Expected $expectedSha1, got $sha1Hash.');
        return;
      }
      print('File verification succeeded: Size and SHA-1 hash match.');
    } catch (e, stackTrace) {
      print('exception: ${e}');
      print(stackTrace);
      throw Exception(e);
    }
  }

  Future<String> computeSha1(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = sha1.convert(bytes);
      return digest.toString();
    } catch (e, stackTrace) {
      print('exception: ${e}');
      print(stackTrace);
      throw Exception(e);
    }
  }
}
