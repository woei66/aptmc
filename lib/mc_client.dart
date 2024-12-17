import 'myvars.dart' as myvars;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'utils.dart';
//import 'download_file.dart';
import 'myvars.dart';
import 'rust_downloader.dart';
import 'java_path_finder.dart';

class MCClient {
  // keep 1 http request to minecraft server to reduce server loading
  //final downloader = DownloadFile(2);
  final downloader = RustDownloader(2);
  Future<void> prepare(String? versionNum) async {
    try {
      print('appDataPath=${appDataPath}');
      final javaPath = await JavaPathFinder.findJavaExecutable();
      if (javaPath != null) {
        print('Java path: $javaPath');
        final version = await JavaPathFinder.getJavaVersion(javaPath);
        print('Version: $version');
      } else {
        print('[error] Java executable not found');
        throw Exception('Java executable not found');
      }
      print('javaPath=${javaPath}');
      await getClientVersion(versionNum);
      await prepareLaunchCommmand();
    } catch (e, stackTrace) {
      print('[exception] catch ${e}');
      print(stackTrace);
      throw Exception(e);
    }
  }

  // preare complete console command string for Minecraft launche
  Future<void> prepareLaunchCommmand() async {
    String launcherCommand = '${javaPath} ${jvmArgs}';
    print('[debug] launcherCommand=${launcherCommand}');
  }

  // get version information
  Future<void> getClientVersion(String? versionNum) async {
    final versionFile = '${appDataPath}/meta/version_manifest.json';
    Map<String, dynamic> jsonData = {};

    if (!File(versionFile).existsSync()) {
      // the version_manifest.json not exists
      try {
        final response = await http.get(Uri.parse(myvars.clientInfoUrl));
        if (response.statusCode == 200) {
          print(
              '[debug][dart] download file=${versionFile}, url=${myvars.clientInfoUrl}');
          // save version file to local disk
          downloader.fetch(myvars.clientInfoUrl, versionFile);
          jsonData = jsonDecode(response.body);
        } else {}
      } catch (e, stackStace) {
        print('[exception] ${e}');
        print(stackStace);
        throw Exception(e);
      }
    } else {
      // the version_manifest.json exists
      try {
        File file = File(versionFile);
        String contents = file.readAsStringSync();
        jsonData = json.decode(contents);
      } catch (e, stackStace) {
        print('[exception] ${e}');
        print(stackStace);
        throw Exception(e);
      }
    }
    try {
      // decode json
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

          parseVersion(versionId, versionUrl);
          break;
        }
      }
    } catch (e, stackStace) {
      print('[exception] ${e}');
      print(stackStace);
      throw Exception(e);
    }
  }

  // parse version detail
  Future<void> parseVersion(String versionId, String url) async {
    Map<String, dynamic> jsonData = {};
    final versionJsonFile = '${appDataPath}/meta/${versionId}.json';

    try {
      if (!File(versionJsonFile).existsSync()) {
        // file not exists
        print('[debug] download ${versionJsonFile} from ${url}');
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          // save to local disk
          downloader.fetch(url, versionJsonFile);
          jsonData = jsonDecode(response.body);
        } else {
          final erroString = '[error] the response is failed. ${url}';
          print(erroString);
          throw Exception(erroString);
        }
      } else {
        // file exists
        File file = File(versionJsonFile);
        String contents = file.readAsStringSync();
        jsonData = json.decode(contents);
      }
    } catch (e, stackTrace) {
      print('[exception] catch ${e}');
      print(stackTrace);
      throw Exception(e);
    }
    // parse response
    await parseGameArgument(versionId, jsonData); // launcher
    await parseJVMArgument(versionId, jsonData); // JVM
    await parseLauncherFile(
        versionId, jsonData); // parse and download Minecraft launcher jar file
    await parseAsset(versionId, jsonData); // parse & download assets
    await parseLibraris(versionId, jsonData); // parse and download libraris
  }

  Future<void> parseGameArgument(String versionId, var jsonData) async {
    final game = jsonData['arguments']['game'];
    List<String> args = [];

    for (int i = 0; i < game.length; i++) {
      if (game[i] is Map<String, dynamic> && game[i]['rules'] == null) {
        // TODO
        //print(game[i]);
      } else if (game[i] is String) {
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
  Future<void> parseJVMArgument(String versionId, var jsonData) async {
    final jvm = jsonData['arguments']['jvm'];
    List<String> args = [];
    for (int i = 0; i < jvm.length; i++) {
      if (jvm[i] is Map<String, dynamic> && jvm[i]['rules'] == null) {
        final rules = jvm[i]['rules'];
        for (int j = 0; j < rules.length; j++) {
          if (rules[j]['os']['name'] == osName) {
            if (!args.contains(rules[j]['value'])) {
              args.add(rules[j]['value']);
            }
          }
        }
      } else if (jvm[i] is String) {
        args.add(jvm[i]);
      }
    }
    if (args.length > 0) {
      jvmArgs = args.join(' ');
      print("[debug] JVM arguments = ${jvmArgs}");
    }
  }

  // parse launcher jar file and download to save in local disk
  Future<void> parseLauncherFile(String versionId, var jsonData) async {
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

    try {
      // get Minecraft client jar file
      clientFile = '${appDataPath}/jar/${versionId}-client.jar';
      await ensureDirectoryExists(clientFile!);
      print('[debug] client jar file= ${clientFile}');
      await downloader.fetch(clientUrl, clientFile!);
      //await downloader.checkFile(clientFile!, clientSize, clientSha1);
    } catch (e, stackStace) {
      print('exception: ${e}');
      print(stackStace);
      throw Exception(e);
    }
  }

  // parse libraris and download to save in local disk
  Future<void> parseLibraris(String versionId, var jsonData) async {
    try {
      for (int i = 0; i < jsonData["libraries"].length; i++) {
        Map<String, dynamic> library = jsonData["libraries"][i];
        final libraryPath = library["downloads"]["artifact"][
            "path"]; // 	"com/google/guava/failureaccess/1.0.1/failureaccess-1.0.1.jar"
        final libraryUrl = library["downloads"]["artifact"][
            "url"]; // 	"https://libraries.minecraft.net/ca/weblite/java-objc-bridge/1.1/java-objc-bridge-1.1.jar"
        final libSha1 = library["downloads"]["artifact"]["sha1"];
        final libSize = library["downloads"]["artifact"]["size"];
        final libName =
            library["name"]; // "com.google.guava:failureaccess:1.0.1"
        final file = '${appDataPath}/libraries/${libraryPath}';
        if (!File(file).existsSync()) {
          print(
              '[debug] download ${i + 1}/${jsonData["libraries"].length} ${file}');
          await ensureDirectoryExists(file);
          await downloader.fetch(libraryUrl, file);
        }
      }
    } catch (e, stackStace) {
      print('exception: ${e}');
      print(stackStace);
      throw Exception(e);
    }
  }

  // parse assets and download to local disk
  Future<void> parseAsset(String versionId, var jsonData) async {
    // asset details
    final assetId = jsonData['assetIndex']['id'];
    final assetUrl = jsonData['assetIndex']['url'];
    final assetSize = jsonData['assetIndex']['size'];
    final assetTotalSize = jsonData['assetIndex']['totalSize'];
    final assetSha1 = jsonData['assetIndex']['sha1'];
    final assetJsonFile = '${appDataPath}/assets/indexes/${assetId}.json';
    //await ensureDirectoryExists(assetJsonFile);
    try {
      if (!File(assetJsonFile).existsSync()) {
        print("[debug] ${assetJsonFile} directory is not extsed");
        await downloader.fetch(assetUrl, assetJsonFile);
      } else {
        //print("[debug] ${assetJsonFile} directory exists");
      }
      Map<String, dynamic> index =
          json.decode(File(assetJsonFile).readAsStringSync());
      List<void Function()> funcs = [];
      //List<Map<String, String>> infos = [];

      int i = 0;
      index["objects"].forEach((key, value) async {
        i++;
        String hash = value["hash"];
        String subhash = hash.substring(0, 2);
        final assetfile = '${appDataPath}/assets/objects/${subhash}/${hash}';
        //await ensureDirectoryExists(assetfile);
        final assetUrl =
            'https://resources.download.minecraft.net/${subhash}/${hash}';
        if (!File(assetfile).existsSync()) {
          print('[debug] download ${i} ${assetfile}');
          await downloader.fetch(assetUrl, assetfile);
        }
      });
    } catch (e, stackStace) {
      print('exception: ${e}');
      print(stackStace);
      throw Exception(e);
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
