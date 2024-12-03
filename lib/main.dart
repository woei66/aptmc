import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mmc9/myvars.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'utils.dart';
import 'mc_client.dart';

void main() async {
  await setupAppDataPath(); // entry point
  runApp(MinecraftLauncher());
}

/*
assets/
cache/
icons/
instances/
libraries/
meta/
themes/
translations/
logs/
config/
jar/
accounts.json
*/
Future<void> setupAppDataPath() async {
  // the application data directory
  final appPath = await getAppDataPath(appName);
  appDataPath = appPath.toString();
  print('Application data path: $appDataPath');
  List<String> subDirs = [
    'assets',
    'cache',
    'icons',
    'instances',
    'libraries',
    'meta',
    'themes',
    'translations',
    'logs',
    'config',
    'jar'
  ];
  // create basic sub directories of application
  for (String dir in subDirs) {
    final subDirPath = '${appDataPath}/${dir}';
    final subDir = Directory(subDirPath);
    if (!await subDir.exists()) {
      await subDir.create(recursive: true);
    }
  }
}

class MinecraftLauncher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MMC9: Minecraft Launcher',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: LauncherHomePage(),
    );
  }
}

class LauncherHomePage extends StatefulWidget {
  @override
  _LauncherHomePageState createState() => _LauncherHomePageState();
}

class _LauncherHomePageState extends State<LauncherHomePage> {
  String _statusMessage = "Preparing to start...";
  bool _isDownloading = false;

  Future<void> checkForUpdates() async {
    setState(() {
      _statusMessage = "Checking status...";
    });

    try {
      final url = "https://api.mojang.com/mc";
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          _statusMessage = "Minecraft is the latest version";
        });
      } else {
        setState(() {
          _statusMessage = "Failed to check updates";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "There is something wrong when checking updates.";
      });
    }
  }

  Future<void> downloadMinecraft() async {
    setState(() {
      _statusMessage = "Downloading ...";
      _isDownloading = true;
    });

    try {
      // get client version and download client jar file
      await MCClient.setup(null);
      setState(() {
        _statusMessage = "Minecraft downloaded successfully.";
        _isDownloading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = "Downloaded failed: $e";
        _isDownloading = false;
      });
    }
  }

  Future<void> launchMinecraft() async {
    setState(() {
      _statusMessage = "Start Minecraft...";
    });

    final dir = await getApplicationDocumentsDirectory();
    String launcherFile = '${dir.path}/minecraft-launcher/minecraft-launcher';

    if (await File(launcherFile).exists()) {
      await Process.start(launcherFile, [], runInShell: true);
      setState(() {
        _statusMessage = "Minecraft is running!";
      });
    } else {
      setState(() {
        _statusMessage = "Minecraft file is not found";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Minecraft Launcher'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _statusMessage,
              style: TextStyle(fontSize: 20),
            ),
            SizedBox(height: 20),
            if (!_isDownloading) ...[
              ElevatedButton(
                onPressed: checkForUpdates,
                child: Text("Check updates"),
              ),
              ElevatedButton(
                onPressed: downloadMinecraft,
                child: Text("Download Minecraft"),
              ),
              ElevatedButton(
                onPressed: launchMinecraft,
                child: Text("Start Minecraft"),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
