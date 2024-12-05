import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'utils.dart';
import 'mc_client.dart';
import 'myvars.dart';

void main() async {
  await getOperatingSystem(); // get operating system name
  await setupAppDataPath(); // application data directory
  runApp(MinecraftLauncher());
}

Future<void> getOperatingSystem() async {
  if (Platform.isWindows) {
    osName = 'windows';
  } else if (Platform.isLinux) {
    osName = 'x86';
  } else if (Platform.isMacOS) {
    osName = 'osx';
  } else if (Platform.isAndroid) {
    osName = 'android';
  } else if (Platform.isIOS) {
    osName = 'ios';
  }
}

/*
assets/ : game assets including sound effect,voice,material,texture from Minecraft resorce server
cache/ : temporary data of Minecraft server including updates,installation packages
icons/ : icons of instances or versions and is used for launcher UI to help player to identify instance
instances/ : to store Minecraft isolated instance,one instance for one isolated game environment(world,mods,configration)
libraries/ : java libraries and related files for Minecraft which are provied by Mojang or 3rd
meta/ : store configuration of launcher including version or index for management
themes/ : customized theme of launcher
translations/ : used by launcher for localization translation.
logs/ : log files of game or launcher including errors,warning or debug information.
config/ : file is ending with .cfg, .json or .xml are used for game or mods configuration.
jar/ : specific Minecraft main .jar files. Ex: daemon
accounts.json : store account information (Microsoft or Mojang) and is stored in encrypted for sing-in automatically.
*/
Future<void> setupAppDataPath() async {
  // the application data directory
  final directory = await getApplicationSupportDirectory();
  final appPath = '${directory.path}/${appName}';
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
