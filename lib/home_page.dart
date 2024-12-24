import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'utils.dart';
import 'minecraft_launcher.dart';
import 'myvars.dart';
import 'file_downloader.dart';
import 'bottom_page.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
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
      final mcClient = MinecraftLauncher();
      await mcClient.prepare(null);
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
        title: Text('Home'),
      ),
      /*body: Padding(
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
      ),*/
      body: MainPage(),
      bottomNavigationBar: const BottomPage(),
    );
  }
}

class MainPage extends StatelessWidget {
  MainPage({Key? key}) : super(key: key);

  String replacePlaceholders(String input, Map<String, String> replacements) {
    replacements.forEach((key, value) {
      input = input.replaceAll(key, value);
    });
    return input;
  }

  // get all class libraries
  String generateClasspath(String baseDir) {
    try {
      final directory = Directory(baseDir);
      if (!directory.existsSync()) {
        print('[warning] Directory does not exist: $baseDir');
        return ''; // Return empty string if directory doesn't exist
      }
      final jars = directory
          .listSync(recursive: true)
          .whereType<File>() // File only
          .where((file) => file.path.endsWith('.jar'))
          .map((file) => file.path)
          .join(':');
      return jars.isNotEmpty
          ? jars
          : ''; // Return empty string if no jars found
    } catch (e, stackTrace) {
      print('[exception] $e');
      return ''; // Return empty string on exception
    }
  }

  // start the stance
  Future<void> startInstance(String instanceFolderName) async {
    for (var item in instanceData) {
      if (item['name'] == instanceFolderName) {
        final mcClient = MinecraftLauncher();
        await mcClient.prepare(item['version'].toString());
        print('[debug] Minecraft version=${item['version']}');
        // java environment
        final environment = mcClient.setJavaEnvironment();
        // appDataPath = /home/woei/.local/share/com.example.aptmc/aptmc/

        final primaryLibraryPath =
            generateClasspath('${appDataPath}/libraries');
        final instanceLibraryPath = generateClasspath(
            '${appDataPath}/instances/${instanceFolderName}/.minecraft/libraries');

        final classpath = [
          primaryLibraryPath,
          if (instanceLibraryPath != null && instanceLibraryPath.isNotEmpty)
            instanceLibraryPath,
          launcherJarFile
        ].where((path) => path != null && path.isNotEmpty).join(':');

        final nativesDir =
            '${appDataPath}/instances/${instanceFolderName}/natives';
        final replacements = {
          '\${natives_directory}': '${nativesDir}',
          '\${launcher_name}': appName,
          '\${launcher_version}': item['version'].toString(),
          '\${classpath}': classpath,
        };

        final jvmArgumentString =
            replacePlaceholders(jvmArguments!, replacements);

        final gameArgumentString = jvmArguments!.replaceAll(
            "\${natives_directory}",
            '${appDataPath}/instances/${instanceFolderName}/natives');

        final arguments = [
          //'-verbose:class',
          jvmArgumentString,
          "net.minecraft.client.main.Main",
          //gameArgumentString,
        ];
        print(arguments);

        try {
          final process = await Process.start(javaPath!, arguments,
              environment: environment);
          stdout.addStream(process.stdout);
          stderr.addStream(process.stderr);
          await process.exitCode;
        } catch (e, stackTrace) {
          print('[error] Failed to start process: $e');
          print(stackTrace);
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    setBottomIconColor('home');
    return LayoutBuilder(
      builder: (context, constraints) {
        // make sure iconsPerRow can't be zero or null
        final iconsPerRow = (constraints.maxWidth / 96)
            .floor()
            .clamp(1, double.infinity)
            .toInt();

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: iconsPerRow,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 8.0,
          ),
          itemCount: instanceData.length,
          itemBuilder: (context, index) {
            final item = instanceData[index];
            return InkWell(
              onTap: () async {
                await startInstance(item['name'].toString());
                // execute preaction if defined
                //if (item['preaction'] != null) {
                //  await (item['preaction'] as Function)();
                //
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(item['icon'] as IconData, size: 48),
                  Text(item['name'] as String),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
