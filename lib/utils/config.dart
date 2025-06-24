import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class ConfigUtils {
  static String? lastWirelessIp;
  static String? lastWirelessPort;
  static bool useWireless = false;
  static bool neverUninstallApps = false;
  static bool exportAllApps = false;
  static bool refreshIcons = false;
  static String? adbPath;

  static Future<File> _getConfigFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/app_manager.json');
  }

  static Future<void> save() async {
    final file = await _getConfigFile();
    final config = {
      'lastWirelessIp': lastWirelessIp,
      'lastWirelessPort': lastWirelessPort,
      'neverUninstallApps': neverUninstallApps,
      'exportAllApps': exportAllApps,
      'refreshIcons': refreshIcons,
      'adbPath': adbPath,
    };
    await file.writeAsString(jsonEncode(config));
  }

  static Future<void> load() async {
    try {
      final file = await _getConfigFile();
      if (await file.exists()) {
        final config = jsonDecode(await file.readAsString());
        lastWirelessIp = config['lastWirelessIp'];
        lastWirelessPort = config['lastWirelessPort'];
        neverUninstallApps = config['neverUninstallApps'] ?? false;
        exportAllApps = config['exportAllApps'] ?? false;
        refreshIcons = config['refreshIcons'] ?? false;
        adbPath = config['adbPath'];
      }
    } catch (_) {}
  }
}