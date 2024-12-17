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
import 'config_parser.dart';

void main() async {
  // the application data directory
  final directory = await getApplicationSupportDirectory();
  final appPath = '${directory.path}/${appName}';
  appDataPath = appPath.toString();
  globalConfigFile = '${appDataPath}/global.cfg';
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

// get all instances
Future<void> getInstances() async {
  try {
    instanceIcons.clear();
    instanceData.clear();

    final instanceDir = '${appDataPath}/instances';
    final directory = Directory(instanceDir!);

    // append a '+' icon
    var instanceKey = {
      'key': 'addInstance',
      'icon': Icons.add_circle,
      'text': 'Add Instance',
      'page': ManagementPage(),
      'preaction': () async {}
    };
    instanceIcons.add(instanceKey);

    if (!directory.existsSync()) {
      // no any instance
      return;
    }

    // add existing instaces
    directory.listSync().forEach((item) async {
      if (item is Directory) {
        final instancecfgFile = '${item.path}/instance.cfg';
        if (await File(instancecfgFile).exists()) {
          final instanceFolderName = item.path.split('/').last;
          //mcInstances.add(instanceFolderName);
          final instance = {
            'key': await sanitizeString(instanceFolderName),
            'icon': Icons.sports_esports,
            'text': instanceFolderName,
            'page': ManagementPage(),
            'preaction': () async {}
          };
          instanceIcons.add(instance);
          Map<String, String> config1 =
              await parseInstanceConfig(instanceFolderName);
          Map<String, dynamic> modPackJson =
              await parseModPackJson(instanceFolderName);
          String? version;
          if (modPackJson.containsKey('components') &&
              modPackJson['components'] is List) {
            final components = modPackJson['components'] as List;
            for (var component in components) {
              if (component is Map<String, dynamic> &&
                  component['uid'] == 'net.minecraft') {
                version = component['version'];
              }
            }
          }
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
            'version': version,
            'name': instanceFolderName,
            'icon': Icons.videogame_asset,
            'lastLaunchTime': launchTime,
            'lastTimePlayed': lastTimePlayed2,
            'totalTimePlayed': totalTimePlayed2,
            'page': ManagementPage(),
            'preaction': () async {}
          };
          instanceData.add(data);
          //print('[debug] instance found ${instanceFolderName}');
        } else {
          // no instance.cfg file, the directory should be deleted??
          print('[debug] directory exists but instance.cfg not found ${item}');
        }
      }
    });
  } catch (e, stackTrace) {
    print('[exception] Failed to get Minecraft instances: $e');
    print(stackTrace);
    rethrow;
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
