import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// copy target/release/librust_downloader.so to assets/rust/linux/librust_downloader.so
// add assets/rust/linux/librust_downloader.so to pubspec.yaml

final DynamicLibrary nativeDownloader = Platform.isLinux
    ? DynamicLibrary.open("assets/rust/linux/librust_downloader.so")
    : DynamicLibrary.process();

class RustDownloader {
  late Pointer<Void> _downloader;

  // Constructor
  RustDownloader(int maxConcurrentRequests) {
    final createDownloader = nativeDownloader.lookupFunction<
        Pointer<Void> Function(Int32),
        Pointer<Void> Function(int)>('create_downloader');
    _downloader = createDownloader(maxConcurrentRequests);
  }

  // Fetch method
  Future<void> fetch(String url, String filename) async {
    try {
      final fetchFile = nativeDownloader.lookupFunction<
          Void Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>),
          void Function(Pointer<Void>, Pointer<Utf8>, Pointer<Utf8>)>(
        'fetch_file',
      );

      final urlC = url.toNativeUtf8();
      final filenameC = filename.toNativeUtf8();
      fetchFile(_downloader, urlC, filenameC);
      malloc.free(urlC);
      malloc.free(filenameC);
    } catch (e, stackTrace) {
      print('[exception][ffi] {$e}');
      print(stackTrace);
      throw Exception(e);
    }
  }

  // Destructor
  void dispose() {
    final freeDownloader = nativeDownloader.lookupFunction<
        Void Function(Pointer<Void>),
        void Function(Pointer<Void>)>('free_downloader');
    freeDownloader(_downloader);
  }
}
