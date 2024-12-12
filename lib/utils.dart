import 'dart:io';

Future<void> ensureDirectoryExists(String filePath) async {
  final subDir = File(filePath).parent;

  //print("[directory] ${filePath}");
  if (!subDir.existsSync()) {
    subDir.createSync(recursive: true);
    //print("[directory] create: ${subDir} ok");
  } else {
    //print("[directory] create: ${subDir} existed");
  }
  /*if (!await subDir.exists()) {
    await subDir.create(recursive: true);
  }*/
}
