import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

final DynamicLibrary nativeDownloader = Platform.isLinux
    ? DynamicLibrary.open("assets/lib/librust_downloader.so")
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
  }

  // Destructor
  void dispose() {
    final freeDownloader = nativeDownloader.lookupFunction<
        Void Function(Pointer<Void>),
        void Function(Pointer<Void>)>('free_downloader');
    freeDownloader(_downloader);
  }
}
