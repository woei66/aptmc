import 'myvars.dart' as myvars;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'utils.dart';
import 'download_file.dart';
import 'myvars.dart';

class MCClient {
  static Future<void> setup(String? versionNum) async {
    try {
      getClientVersion(versionNum);
    } catch (e) {
      print("exception: ${e}");
    }
  }

  // get version information
  static Future<void> getClientVersion(String? versionNum) async {
    final response = await http.get(Uri.parse(myvars.clientInfoUrl));
    if (response.statusCode == 200) {
      // save version file to local disk
      DownloadFile.download(
          myvars.clientInfoUrl, '${appDataPath}/meta/version_manifest.json');
      // decode response data
      final jsonData = jsonDecode(response.body);
      final release = jsonData['latest']['release'];
      final snapshot = jsonData['latest']['snapshot'];

      versionNum ??= release;

      List versions = jsonData['versions'];
      print("[debug] client version=${versionNum}");
      for (final version in versions) {
        if (version['id'] == versionNum) {
          // "https://piston-meta.moja…04e4649/1.21.4-pre3.json"
          final versionUrl = version['url'];
          final versionId = version['id']; // 	"1.21.4-pre3"
          final versionType = version['type']; // "2024-11-29T09:27:51+00:00"
          final versionTime = version['time']; // "2024-11-26T15:07:29+00:00"
          final versionReleaseTime = version['releaseTime'];

          instanceName ??= versionId;

          parseVersion(versionId, versionUrl);

          break;
        }
      }
    }
  }

  // parse version detail
  static Future<void> parseVersion(String versionId, String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      print('[debug] clientInfoUrl = ${url}');
      if (response.statusCode == 200) {
        // save to local disk
        final versionJsonFile = '${appDataPath}/meta/${versionId}.json';
        if (!File(versionJsonFile).existsSync()) {
          DownloadFile.download(url, versionJsonFile);
        }

        final jsonData = jsonDecode(response.body);
        // parse response
        await parseGameArgument(versionId, jsonData); // launcher
        await parseJVMArgument(versionId, jsonData); // JVM
        await parseLauncherFile(versionId,
            jsonData); // parse and download Minecraft launcher jar file
        await parseAsset(versionId, jsonData); // parse & download assets
        await parseLibraris(versionId, jsonData); // parse and download libraris
      } else {
        print('Error: the response is failed.');
      }
    } catch (e) {
      print('[exception] catch ${e}');
    }
  }

  static Future<void> parseGameArgument(String versionId, var jsonData) async {
    final game = jsonData['arguments']['game'];
    List<String> args = [];
    for (int i = 0; i < game.length; i++) {
      if (game[i]['rules'] != null) {
        // TODO
      } else {
        args.add(game[i]);
      }
    }
    if (args.length > 0) {
      gameArgs = args.join(' ');
      print("[debug] game arguments=${gameArgs}");
    }
  }
// yggdrasil: the authentication system for Minecraft after 1.6-pre
  // yggdrasil: using access token to replace the user/password
  // "--username"
  // "${auth_player_name}"
  // "--uuid"
  // "${auth_uuid}"

  // parse JVM arguments
  static Future<void> parseJVMArgument(String versionId, var jsonData) async {
    final jvm = jsonData['arguments']['jvm'];
    List<String> args = [];
    for (int i = 0; i < jvm.length; i++) {
      if (jvm[i]['rules'] != null) {
        final rules = jvm[i]['rules'];
        for (int j = 0; j < rules.length; j++) {
          if (rules[j]['os']['name'] == osName) {
            if (!args.contains(rules[j]['value'])) {
              args.add(rules[j]['value']);
            }
          }
        }
      } else {
        args.add(jvm[i]);
      }
    }
    if (args.length > 0) {
      jvmArgs = args.join(' ');
      print("[debug] JVM arguments=${jvmArgs}");
    }
  }

  // parse launcher jar file and download to save in local disk
  static Future<void> parseLauncherFile(String versionId, var jsonData) async {
    final downloads = jsonData['downloads'];
    // Minecraft launcher download
    final clientSha1 = downloads['client']['sha1'];
    final clientSize = downloads['client']['size'];
    final clientUrl = downloads['client']['url'];
    final argGame = jsonData['arguments']['game'];
    final argJvm = jsonData['arguments']['jvm'];
    final assetIndex = jsonData['assetIndex'];
    final javaVersion = jsonData['javaVersion'];
    final libraries = jsonData['libraries'];
    final logging = jsonData['logging'];
    final mainClass = jsonData['mainClass'];
    final minimumLauncherVersion = jsonData['minimumLauncherVersion'];
    final releaseTime = jsonData['releaseTime'];

    // get Minecraft client jar file
    clientFile = '${appDataPath}/jar/${versionId}-client.jar';
    await createDirectoryIfNotExists(clientFile!);
    print('[debug] client file= ${clientFile}');
    await DownloadFile.download(clientUrl, clientFile!);
    //await DownloadFile.checkFile(clientFile!, clientSize, clientSha1);
  }

  // parse libraris and download to save in local disk
  static Future<void> parseLibraris(String versionId, var jsonData) async {
    for (int i = 0; i < jsonData["libraries"].length; i++) {
      Map<String, dynamic> library = jsonData["libraries"][i];
      final libraryPath = library["downloads"]["artifact"][
          "path"]; // 	"com/google/guava/failureaccess/1.0.1/failureaccess-1.0.1.jar"
      final libraryUrl = library["downloads"]["artifact"][
          "url"]; // 	"https://libraries.minecraft.net/ca/weblite/java-objc-bridge/1.1/java-objc-bridge-1.1.jar"
      final libSha1 = library["downloads"]["artifact"]["sha1"];
      final libSize = library["downloads"]["artifact"]["size"];
      final libName = library["name"]; // "com.google.guava:failureaccess:1.0.1"
      final file = '${appDataPath}/libraries/${libraryPath}';
      await DownloadFile.download(libraryUrl, file);
    }
  }

  // parse assets and download to local disk
  static Future<void> parseAsset(String versionId, var jsonData) async {
    // asset details
    final assetId = jsonData['assetIndex']['id'];
    final assetUrl = jsonData['assetIndex']['url'];
    final assetSize = jsonData['assetIndex']['size'];
    final assetTotalSize = jsonData['assetIndex']['totalSize'];
    final assetSha1 = jsonData['assetIndex']['sha1'];
    final assetJsonFile = '${appDataPath}/assets/indexes/${assetId}.json';
    if (!File(assetJsonFile).existsSync()) {
      DownloadFile.download(assetUrl, assetJsonFile);
    }
    Map<String, dynamic> index =
        json.decode(File(assetJsonFile).readAsStringSync());
    List<void Function()> funcs = [];
    //List<Map<String, String>> infos = [];

    index["objects"].forEach((key, value) {
      String hash = value["hash"];
      String subhash = hash.substring(0, 2);
      final assetfile = '${appDataPath}/objects/${subhash}/${hash}';
      final assetUrl =
          'https://resources.download.minecraft.net/${subhash}/${hash}';
      if (!File(assetfile).existsSync()) {
        DownloadFile.download(assetUrl, assetfile);
      }
    });
  }

  // create directory if not exists
  static Future<void> createDirectoryIfNotExists(String filePath) async {
    final directory = Directory(filePath).parent;

    if (!directory.existsSync()) {
      print('Directory does not exist. Creating: ${directory.path}');
      directory.createSync(recursive: true);
    }
  }
}

// files and directory in .minecraft
/*
config/ : configuration files of mods. ex: game rules, visual effect, functions
coremods/ : core mods for basic functions or used by other mods. this directory is depreciated and is replaced by mods/ and libraries/
data/ : some mods put data in this folder. ex: customized data,statistic data, mods specific data.
libraries/ : files of core game, mod framework(ex:forge,fabric)
logs/ : to store game logs, events of playing, tunning or analytics error.
mods/ : for mods, files with .jar additional file name and will be loaded by game
resourcepacks/ : for texture, sound effect
saves/ : single player store files, one world one directory.
screenshots/ : screenshot when press F2
server-resource-packs/ : resource files from Minecraft server and server will force players to modify game visual or game effect.
shaderpacks/ : for shaders to improve light effect.
showdown/ : specific mods or plugins will use this directory and should be mod related.
texturepacks/ : this directory is depreciated and replaced by resourcepacks/. It's used by old Minecraft.
versions/ : store core files of different game versions. One directory for one version. Ex. official, fabric, forge.
.fabric/ : fabric only directory to store related files of fabric
crash-reports/ : store crash logs with details for trouble shotting.
defaultconfigs/ : default directory for mods and used for new world or server configuration.
icon.png : icon of server and this icon wil be showed on server list to identy.
options.txt : global settings of game. Ex. key binding,volume, graphic setting.
servers.dat : list of servers and store added server information.
servers.dat_old : backup file of servers.data
usercache.json : players' UUID, name and used for multi-players.
*/
