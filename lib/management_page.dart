import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'utils.dart';
import 'mc_client.dart';
import 'myvars.dart';
import 'download_file.dart';
import 'bottom_page.dart';

class ManagementPage extends StatefulWidget {
  @override
  _ManagementPageState createState() => _ManagementPageState();
}

class _ManagementPageState extends State<ManagementPage> {
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
      final mcClient = MCClient();
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
        title: Text('APTMC Minecraft'),
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
      body: InstanceListPage(),
      bottomNavigationBar: const BottomPage(),
    );
  }
}

class InstanceListPage extends StatelessWidget {
  InstanceListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 固定的表頭
        Container(
          color: Colors.grey[300],
          child: Row(
            children: [
              _buildHeaderCell('Name'),
              _buildHeaderCell('Version'),
              _buildHeaderCell('Last launch'),
              _buildHeaderCell('Last time played'),
              _buildHeaderCell('Total time played'),
            ],
          ),
        ),
        // 可滾動的資料區域
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: instanceData.map((item) {
                return Row(
                  children: [
                    _buildDataCell(item['name']?.toString() ?? ''),
                    _buildDataCell(item['version']?.toString() ?? ''),
                    _buildDataCell(item['lastLaunchTime']?.toString() ?? ''),
                    _buildDataCell(item['lastTimePlayed']?.toString() ?? ''),
                    _buildDataCell(item['totalTimePlayed']?.toString() ?? ''),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderCell(String title) {
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildDataCell(String data) {
    return Expanded(
      flex: 1,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(data),
      ),
    );
  }
}
