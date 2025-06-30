import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:app_manager/services/manager.dart';
import 'package:app_manager/utils/config.dart';
import 'package:app_manager/utils/localization.dart';

class FileManager {
  static Future<String?> selectDirectory({String? dialogTitle}) async {
    return await FilePicker.platform.getDirectoryPath(
      dialogTitle: dialogTitle ?? Localization.translate('select_directory'),
    );
  }

  static Future<void> selectAdbFolder(BuildContext context) async {
    final result = await selectDirectory(dialogTitle: Localization.translate('select_adb_folder'));
    if (result != null) {
      final adbPath = Platform.isWindows ? '$result\\adb.exe' : '$result/adb';
      final file = File(adbPath);
      if (await file.exists()) {
        ConfigUtils.adbPath = adbPath;
        await ConfigUtils.save();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${Localization.translate('adb_path_set')} $adbPath')),
        );
        Navigator.of(context, rootNavigator: false).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Localization.translate('no_valid_adb_executable'))),
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
        SnackBar(content: Text(Localization.translate('no_actions_to_export'))),
      );
      return;
    }

    final jsonStr = const JsonEncoder.withIndent('  ').convert(exportList);
    final now = DateTime.now();
    final fileName = 'AppList-${now.day.toString().padLeft(2, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.year}.json';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: Localization.translate('export_actions_json'),
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
      SnackBar(content: Text('${Localization.translate('exported_to')} $normalizedSavePath')),
    );
  }

  static Future<void> importJsonString(BuildContext context, String jsonStr) async {
    List<dynamic> imported;
    try {
      imported = json.decode(jsonStr);
      if (imported.isEmpty) throw Exception('Empty JSON.');
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(Localization.translate('invalid_json'))),
      );
      return;
    }
    await _applyImportedActions(context, imported);
  }

  static Future<void> importAppActions(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: Localization.translate('import_actions_json'),
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
      SnackBar(content: Text('${Localization.translate('applied_actions')} $applied ${Localization.translate('actions_suffix')}')),
    );
  }

  static Future<void> exportAppIcon(BuildContext context, String package, String iconPath) async {
    final now = DateTime.now();
    final fileName = '${package}_icon_${now.day.toString().padLeft(2, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-${now.year}.png';

    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: Localization.translate('export_app_icon'),
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
        SnackBar(content: Text(Localization.translate('icon_file_not_found'))),
      );
      return;
    }

    await srcFile.copy(normalizedSavePath);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${Localization.translate('icon_exported_to')} $normalizedSavePath')),
    );
  }
}