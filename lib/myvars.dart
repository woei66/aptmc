import 'dart:io';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

String? launcherMSAClientID;
String? curseforgeAPIKey;

// basic
const resourceBaseUrl = 'https://resources.download.minecraft.net/';
const libraryBaseUrl = 'https://libraries.minecraft.net/';

// Minecraft related
const mojangAuthBaseUrl = 'https://authserver.mojang.com';
const mojangAccountBaseUrl = 'https://api.mojang.com';
const mojangSessionBaseUrl = 'https://sessionserver.mojang.com';
const mojangServicesBaseUrl = 'https://api.minecraftservices.com';
// 3-rd resources
const modpackshBaseUrl = "https://api.modpacks.h/";
const legacyFTBBaseUrl = "https://dist.creeper.host/FTB2/";
const atlDownloadUrl = "https://download.nodecdn.net/containers/atl/";
const atlAPIBaseUrl = "https://api.atlauncher.com/v1/";
const technicpackApiBaseUrl = "https://api.technicpack.net/";
const modrinthStagingUrl = "https://staging-api.modrinth.com/v2";
const modrithProdUrl = "https://api.modrinth.com/v2";
// download files
const clientInfoUrl =
    'https://launchermeta.mojang.com/mc/game/version_manifest.json';
// icon
const iconUrl = 'https://launcher.mojang.com/download/minecraft-launcher.svg';
// Minecraft launcher client jar file
String? minecraftLauncherPath;
// multiple instance name and directory. Ex: instances/1.20.1-pokemon-fabric/.minecraft/
String? appDataPath;
// application name
const appName = 'aptmc';
// operating system
String? osName;
// JVM arguments
String? jvmArguments;
String? gameArguments;
String? javaPath;
// instances name
//List<String> mcInstances = [];
// instances icon
List<Map<String, Object?>> instanceIcons = [];
List<Map<String, Object?>> instanceData = [];
// global configuration file for all instances as default value
String? globalConfigFile;
// full command of launcher
String? fullCommand;
// color of bottom page
Map<String, Color> bottomIconColor = {
  'home': Colors.blue,
  'instance': Colors.black,
  'setting': Colors.black,
  'account': Colors.black,
};
