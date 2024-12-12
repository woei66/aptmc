import 'dart:io';
import 'dart:convert';
import 'package:path/path.dart' as path;

class JavaPathFinder {
  /// Finds the Java executable path across Windows, macOS, and Linux
  ///
  /// Returns the full path to the Java executable, or null if not found
  static Future<String?> findJavaExecutable() async {
    if (Platform.isWindows) {
      return await _findJavaOnWindows();
    } else if (Platform.isMacOS) {
      return await _findJavaOnMacOS();
    } else if (Platform.isLinux) {
      return await _findJavaOnLinux();
    }
    return null;
  }

  /// Find Java path on Windows
  static Future<String?> _findJavaOnWindows() async {
    // Try common Java installation paths
    final commonPaths = [
      r'C:\Program Files\Java',
      r'C:\Program Files (x86)\Java',
      path.join(Platform.environment['USERPROFILE']!, 'java')
    ];

    // Check system PATH
    final pathEnv = Platform.environment['PATH']?.split(';') ?? [];

    // Combine common paths with PATH entries
    final searchPaths = [...commonPaths, ...pathEnv];

    // Look for java.exe in these paths
    for (var basePath in searchPaths) {
      final javaExe = _findJavaExeInPath(basePath, 'java.exe');
      if (javaExe != null) return javaExe;
    }

    // Try using 'where' command
    try {
      final result = await Process.run('where', ['java']);
      if (result.exitCode == 0) {
        final path = (result.stdout as String).trim().split('\n').first;
        if (await File(path).exists()) return path;
      }
    } catch (_) {}

    return null;
  }

  /// Find Java path on macOS
  static Future<String?> _findJavaOnMacOS() async {
    try {
      // Try using /usr/libexec/java_home
      final result = await Process.run('/usr/libexec/java_home', []);
      if (result.exitCode == 0) {
        final javaHome = (result.stdout as String).trim();
        final javaPath = path.join(javaHome, 'bin', 'java');
        if (await File(javaPath).exists()) return javaPath;
      }
    } catch (_) {}

    // Check common paths and PATH
    final commonPaths = [
      '/Library/Java/JavaVirtualMachines',
      '/System/Library/Java/JavaVirtualMachines',
      path.join(Platform.environment['HOME']!, 'java')
    ];

    final pathEnv = Platform.environment['PATH']?.split(':') ?? [];
    final searchPaths = [...commonPaths, ...pathEnv];

    for (var basePath in searchPaths) {
      final javaExe = _findJavaExeInPath(basePath, 'java');
      if (javaExe != null) return javaExe;
    }

    return null;
  }

  /// Find Java path on Linux
  static Future<String?> _findJavaOnLinux() async {
    // Try using 'which' command
    try {
      final result = await Process.run('which', ['java']);
      if (result.exitCode == 0) {
        final path = (result.stdout as String).trim();
        if (await File(path).exists()) return path;
      }
    } catch (_) {}

    // Check common paths
    final commonPaths = [
      '/usr/lib/jvm',
      '/usr/local/java',
      '/opt/java',
      path.join(Platform.environment['HOME']!, 'java')
    ];

    final pathEnv = Platform.environment['PATH']?.split(':') ?? [];
    final searchPaths = [...commonPaths, ...pathEnv];

    for (var basePath in searchPaths) {
      final javaExe = _findJavaExeInPath(basePath, 'java');
      if (javaExe != null) return javaExe;
    }

    return null;
  }

  /// Helper method to find java executable in a given path
  static String? _findJavaExeInPath(String basePath, String exeName) {
    try {
      final dir = Directory(basePath);
      if (!dir.existsSync()) return null;

      // Recursive search for java executable
      final javaFiles = dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((file) => path.basename(file.path) == exeName);

      return javaFiles.isNotEmpty ? javaFiles.first.path : null;
    } catch (_) {
      return null;
    }
  }

  /// Verify Java installation and get version
  static Future<String?> getJavaVersion(String javaPath) async {
    try {
      final result = await Process.run(javaPath, ['-version']);
      if (result.exitCode == 0) {
        // Java version info is typically printed to stderr
        final versionOutput = (result.stderr as String).trim();
        return versionOutput.split('\n').first;
      }
    } catch (_) {}
    return null;
  }
}
