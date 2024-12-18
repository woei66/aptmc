import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'utils.dart';
import 'minecraft_launcher.dart';
import 'myvars.dart';
import 'file_downloader.dart';
import 'bottom_page.dart';

class InstanceAddPage extends StatefulWidget {
  @override
  _InstanceAddPageState createState() => _InstanceAddPageState();
}

class _InstanceAddPageState extends State<InstanceAddPage> {
  String _statusMessage = "Preparing to start...";
  bool _isDownloading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Instances Editing'),
      ),
      body: InstanceEditContentPage(),
      bottomNavigationBar: const BottomPage(),
    );
  }
}

class InstanceEditContentPage extends StatelessWidget {
  InstanceEditContentPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // fixed header
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
        // scrollable instance list
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: instanceData.map((item) {
                return GestureDetector(
                    // the whole row is clickable
                    onTapDown: (TapDownDetails details) {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => InstanceAddPage()));
                    },
                    child: Row(
                      children: [
                        _buildDataCell(item['name']?.toString() ?? ''),
                        _buildDataCell(item['version']?.toString() ?? ''),
                        _buildDataCell(
                            item['lastLaunchTime']?.toString() ?? ''),
                        _buildDataCell(
                            item['lastTimePlayed']?.toString() ?? ''),
                        _buildDataCell(
                            item['totalTimePlayed']?.toString() ?? ''),
                      ],
                    ));
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
