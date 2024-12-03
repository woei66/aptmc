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
        final jsonData = jsonDecode(response.body);

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

        final clientFile = '${appDataPath}/jar/${versionId}-client.jar';
        createDirectoryIfNotExists(clientFile);

        print('[debug] client file= ${clientFile}');
        await DownloadFile.download(clientUrl, clientFile);
        await DownloadFile.checkFile(clientFile, clientSize, clientSha1);
        mcClientFile = clientFile;
      } else {
        print('Error: the response is failed.');
      }
    } catch (e) {
      print('[exception] catch ${e}');
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
