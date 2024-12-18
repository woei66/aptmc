import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'utils.dart';
import 'myvars.dart';
import 'dart:convert';
import 'dart:io';

// parse global configuration file: global.cfg
// file format: key=value
// return value: Map<String,String>
Future<Map<String, String>> parseGlobalConfig() async {
  final config = <String, String>{};

  try {
    final file = File(globalConfigFile!);
    if (!await file.exists()) {
      throw Exception('[error] File not found: ${globalConfigFile!}');
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
    rethrow;
  }
  return config;
}

// parse instance.cfg file
// input: folder name of instance
// file format: key=value
// return value: Map<String,String>
Future<Map<String, String>> parseInstanceConfig(
    String instanceFolderName) async {
  final config = <String, String>{};
  final filename =
      '${appDataPath}/instances/${instanceFolderName}/instance.cfg';
  final file = File(filename);

  try {
    if (!await file.exists()) {
      throw Exception('[error] File not found: $filename');
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
    rethrow;
  }
  return config;
}

// parse mods configuration of instances
// input : instance folder name
// file format: json
// return value: Map<String,String>
Future<Map<String, dynamic>> parseModPackJson(String instanceFolderName) async {
  final filename =
      '${appDataPath}/instances/${instanceFolderName}/mmc-pack.json';
  try {
    final file = File(filename);
    // Read the JSON file as a string
    if (!await file.exists()) {
      throw Exception("File not found: $filename");
    }

    final contents = await file.readAsString();

    // Parse the JSON string into a Map
    final Map<String, dynamic> jsonData = jsonDecode(contents);

    // Ensure the JSON structure contains 'components'

    if (jsonData.containsKey('components') && jsonData['components'] is List) {
      /*final components = jsonData['components'] as List;

      for (var component in components) {
        if (component is Map<String, dynamic>) {
          print('Component:');
          component.forEach((key, value) {
            if (key == 'cachedRequires' && value is List) {
              print('  $key:');
              for (var requirement in value) {
                print('    $requirement');
              }
            } else {
              print('  $key: $value');
            }
          });
        }
      }*/
    } else {
      print(
          '[error] Invalid mods json structure: Missing or invalid "components".');
    }

    return jsonData;
  } catch (e) {
    // Handle errors during file reading or JSON parsing
    print('[error] Error reading or parsing the JSON file: $e');
    rethrow;
  }
}
