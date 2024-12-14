import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'utils.dart';
import 'mc_client.dart';
import 'myvars.dart';
import 'download_file.dart';
import 'home_page.dart';
import 'management_page.dart';
import 'dart:convert';
import 'dart:io';

void main() async {
  // the application data directory
  final directory = await getApplicationSupportDirectory();
  final appPath = '${directory.path}/${appName}';
  appDataPath = appPath.toString();
  //print('Application data path: $appDataPath');
  // get all Minecraft instances
  await getInstances();
  // get operating system name
  await getOperatingSystem();
  // application data directory
  await setupAppDataPath();
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

// parse instance details
Future<Map<String, String>> parseMMCPackJsonFile(String folder) async {
  final filename = '${folder}/mmc-pack.json';
  final file = File(filename);
  Map<String, String> config = {};
  print('[debug] instance config file = ${filename}');
  try {
    if (!file.existsSync()) {
      // if file not exists, throw exception
      print('[error] ${filename} not found');
      throw Exception('[error] ${filename} not found');
    }
    // file exists
    final contents = await file.readAsString();
    final data = jsonDecode(contents);
    String? minecraftVersion;
    if (data is Map && data['components'] is List) {
      final components = data['components'] as List;
      for (final component in components) {
        if (component is Map && component['uid'] == 'net.minecraft') {
          config['version'] = component['version'] as String;
        }
      }
    }
    return config;
  } catch (e, stackTrace) {
    print('[exception] ${e}');
    print(stackTrace);
    throw Exception(e);
  }
}

// parse instance.cfg file
Future<Map<String, String>> parseInstanceCFGFile(String filePath) async {
  final config = <String, String>{};

  try {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('[error] File not found: $filePath');
    }

    final lines = await file.readAsLines();

    for (final line in lines) {
      // skip empty or comment line
      if (line.trim().isEmpty || line.startsWith('#')) {
        continue;
      }

      // split and get key/value pair
      final parts = line.split('=');
      if (parts.length == 2) {
        final key = parts[0].trim();
        final value = parts[1].trim();
        config[key] = value;
      } else {
        print('[error] Ignored malformed line: $line');
      }
    }
  } catch (e) {
    print('[error] Error reading config file: $e');
    throw Exception(e);
  }
  return config;
}

// get all instances
Future<void> getInstances() async {
  try {
    //mcInstances.clear();
    instanceIcons.clear();
    instanceData.clear();

    final instanceDir = '${appDataPath}/instances';
    final directory = Directory(instanceDir!);
    if (!directory.existsSync()) {
      await ensureDirectoryExists(appDataPath!);
    }

    // append a '+' icon
    var instanceKey = {
      'key': 'addInstance',
      'icon': Icons.add_circle,
      'text': 'Add Instance',
      'page': ManagementPage(),
      'preaction': () async {}
    };
    instanceIcons.add(instanceKey);

    // add existing instaces
    directory.listSync().forEach((item) async {
      if (item is Directory) {
        final instancecfgFile = '${item.path}/instance.cfg';
        if (await File(instancecfgFile).exists()) {
          final instanceName = item.path.split('/').last;
          //mcInstances.add(instanceName);
          final instance = {
            'key': await sanitizeString(instanceName),
            'icon': Icons.sports_esports,
            'text': instanceName,
            'page': ManagementPage(),
            'preaction': () async {}
          };
          instanceIcons.add(instance);
          Map<String, String> config1 =
              await parseInstanceCFGFile(instancecfgFile);
          Map<String, String> config2 = await parseMMCPackJsonFile(item.path);
          final launchTime = DateTime.fromMillisecondsSinceEpoch(
              int.parse(config1['lastLaunchTime']!));
          final lastTimePlayed1 =
              Duration(seconds: int.parse(config1['lastTimePlayed']!));
          final lastTimePlayed2 =
              '${lastTimePlayed1.inHours} hours, ${lastTimePlayed1.inMinutes % 60} minutes';
          final totalTimePlayed1 =
              Duration(seconds: int.parse(config1['totalTimePlayed']!));
          final totalTimePlayed2 =
              '${totalTimePlayed1.inHours} hours, ${totalTimePlayed1.inMinutes % 60} minutes';
          final data = {
            'version': config2['version'],
            'name': instanceName,
            'icon': Icons.videogame_asset,
            'lastLaunchTime': launchTime,
            'lastTimePlayed': lastTimePlayed2,
            'totalTimePlayed': totalTimePlayed2,
            'page': ManagementPage(),
            'preaction': () async {}
          };
          instanceData.add(data);
          //print('[debug] instance found ${instanceName}');
        } else {
          // no instance.cfg file, the directory should be deleted??
          print('[debug] directory exists but instance.cfg not found ${item}');
        }
      }
    });
  } catch (e, stackTrace) {
    print('[exception] Failed to get Minecraft instances: $e');
    print(stackTrace);
    throw Exception('Failed to get Minecraft instances: $e');
  }
}

class MinecraftLauncher extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'APTMC Launcher',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: HomePage(),
    );
  }
}
