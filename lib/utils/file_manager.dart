import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:app_manager/services/manager.dart';
import 'package:app_manager/utils/config.dart';

class FileManager {
  static Future<String?> selectDirectory({String? dialogTitle}) async {
    return await FilePicker.platform.getDirectoryPath(
      dialogTitle: dialogTitle ?? 'Select directory',
    );
  }

  static Future<void> selectAdbFolder(BuildContext context) async {
    final result = await selectDirectory(dialogTitle: 'Select ADB folder');
    if (result != null) {
      final adbPath = Platform.isWindows ? '$result\\adb.exe' : '$result/adb';
      final file = File(adbPath);
      if (await file.exists()) {
        ConfigUtils.adbPath = adbPath;
        await ConfigUtils.save();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ADB path set to $adbPath')),
        );
        Navigator.of(context, rootNavigator: false).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No valid ADB executable found in selected folder.')),
        );
      }
    }
  }

  static Future<void> exportAppActions(BuildContext context) async {
    final exportList = <Map<String, dynamic>>[];
    final isUninstallable = !ConfigUtils.neverUninstallApps;
    final allowAllApps = ConfigUtils.exportAllApps;
    for (final app in ManagerService.apps.values) {
      final checked = app['isChecked'];
      final state = app['state'];
      String? action;
      if (state > 0 && !checked) {
        action = isUninstallable ? 'uninstall' : 'deactivate';
      } else if (state == 0 && checked) {
        action = 'activate';
      } else if (state < 0 && checked) {
        action = 'install';
      } else if (allowAllApps) {
        if (state > 0) {
          action = 'install';
        } else if (state == 0) {
          action = 'deactivate';
        } else if (state < 0) {
          action = 'uninstall';
        }
      }
      if (action != null) {
        exportList.add({
          'package': app['package'],
          'action': action,
        });
      }
    }

    if (exportList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No actions to export.')),
      );
      return;
    }

    final jsonStr = const JsonEncoder.withIndent('  ').convert(exportList);
    final now = DateTime.now();
    final fileName = 'AppList-${now.day.toString().padLeft(2, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.year}.json';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export actions as JSON',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (savePath == null) return;

    final normalizedSavePath = savePath.toLowerCase().endsWith('.json')
        ? savePath
        : '$savePath.json';

    final file = File(normalizedSavePath);
    await file.writeAsString(jsonStr);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported to $normalizedSavePath')),
    );
  }

  static Future<void> importJsonString(BuildContext context, String jsonStr) async {
    List<dynamic> imported;
    try {
      imported = json.decode(jsonStr);
      if (imported.isEmpty) throw Exception('Empty JSON.');
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid JSON.')),
      );
      return;
    }
    await _applyImportedActions(context, imported);
  }

  static Future<void> importAppActions(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Import actions JSON',
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result == null || result.files.isEmpty) return;

    final file = File(result.files.single.path!);
    final jsonStr = await file.readAsString();
    await importJsonString(context, jsonStr);
  }

  static Future<void> _applyImportedActions(BuildContext context, List<dynamic> imported) async {
    int applied = 0;
    for (final item in imported) {
      if (item is! Map) continue;
      final pkg = item['package'];
      final action = item['action'];
      final app = ManagerService.apps[pkg];
      if (app == null) continue;

      final state = app['state'];
      if ((action == 'uninstall' || action == 'deactivate') && state > 0) {
        app['isChecked'] = false;
        applied++;
      } else if (action == 'deactivate' && state < 0) {
        app['action'] = 'install-disable';
        applied++;
      } else if ((action == 'install' || action == 'activate') && state <= 0) {
        app['isChecked'] = true;
        applied++;
      }
    }
    ManagerService.updateActionCounters();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Applied $applied actions.')),
    );
  }

  static Future<void> exportAppIcon(BuildContext context, String package, String iconPath) async {
    final now = DateTime.now();
    final fileName = '${package}_icon_${now.day.toString().padLeft(2, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-${now.year}.png';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Export app icon',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: ['png'],
    );

    if (savePath == null) return;

    final normalizedSavePath = savePath.toLowerCase().endsWith('.png')
        ? savePath
        : '$savePath.png';

    final srcFile = File(iconPath);
    if (!await srcFile.exists()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Icon file not found.')),
      );
      return;
    }

    await srcFile.copy(normalizedSavePath);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Icon exported to $normalizedSavePath')),
    );
  }
}