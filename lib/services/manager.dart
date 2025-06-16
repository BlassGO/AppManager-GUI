import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_manager/services/adb.dart';
import 'package:app_manager/overlays/alert.dart';
import 'package:app_manager/overlays/load.dart';
import 'package:app_manager/utils/config.dart';

class ManagerService {
  static Map<String, Map<String, dynamic>> apps = {};
  static String? userId;

  static int activateCount = 0;
  static int installCount = 0;
  static int deactivateCount = 0;
  static int uninstallCount = 0;

  static bool? pmSupportsInstallExisting;
  static bool? pmSupportsUserFlag;
  static bool? pmSupportsDisableUser;
  static bool iconsLoaded = false;
  static bool appManagerPushed = false;

  static Future<void> reset() async {
    iconsLoaded = false;
    appManagerPushed = false;
    pmSupportsInstallExisting = null;    
  }

  static Future<void> setPMFlagSupport() async {
    if (pmSupportsInstallExisting == null) {
      final output = await AdbService.runShell('pm help', toLog: false);
      pmSupportsInstallExisting = output.contains('install-existing');
      pmSupportsDisableUser = output.contains('disable-user');
      pmSupportsUserFlag = output.contains('--user');
    }
  }

  static Future<bool> prepareAppManager(BuildContext context) async {
    if (appManagerPushed) return true;
    try {
      final bytes = await rootBundle.load('assets/app_manager');
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/app_manager'.replaceAll('\\', '/'));
      await tempFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);

      await AdbService.pushFile(
        tempFile.path,
        '/data/local/tmp/app_manager'
      );

      if (AdbService.hasError()) {
        Alert.showWarning(
          context,
          'Failed to transfer app_manager to device.\n\nSee log for details.'
        );
        return false;
      }
      appManagerPushed = true;
      return true;
    } catch (e) {
      Alert.showWarning(context, 'Error preparing app_manager: $e');
      return false;
    }
  }

  static void parseAppManagerOutput(String output) {
    userId = null;
    apps.clear();

    final lines = output.split(RegExp(r'[\r\n]+'));
    for (final line in lines) {
      if (line.trim().isEmpty) continue;
      if (line.startsWith('USER:')) {
        userId = line.substring(5).trim();
        continue;
      }
      final info = line.replaceAll('\u00A0', ' ').split(':');
      if (info.length == 6) {
        final pkg = info[3].trim();
        final stateStr = info[0].trim();
        final systemStr = info[1].trim();
        final app = <String, dynamic>{
          'state': stateStr == 'ENABLED'
              ? 1
              : (stateStr == 'DISABLED' ? 0 : -1),
          'isSystem': systemStr == 'SYSTEM',
          'isChecked': stateStr == 'ENABLED',
          'isExpanded': false,
          'package': pkg,
          'path': info[4].trim(),
          'name': info[5].trim(),
          'id': info[2].trim(),
        };
        apps[pkg] = app;
      }
    }
  }

  static String buildUserFlag() {
    if (userId != null && userId != 'null' && pmSupportsUserFlag == true) {
      return '--user $userId ';
    }
    return '';
  }

  static List<String> buildActions() {
    final userFlag = buildUserFlag();
    final actions = <String>[];
    final isUninstallable = !ConfigUtils.neverUninstallApps;
    apps.forEach((pkg, app) {
      final checked = app['isChecked'];
      final doBefore = app['doBefore'];
      final path = app['path'];
      int state = app['state'];
      if (doBefore == 'install-disable') {
          if (pmSupportsInstallExisting == true) {
            actions.add('pm install-existing $userFlag$pkg && echo -- Installed $pkg');
          } else {
            actions.add('pm install -r $userFlag"$path" && echo -- Installed $path');
          }
          if (pmSupportsDisableUser == true) {
            actions.add('pm disable-user $userFlag$pkg && echo -- Disabled $pkg');
          } else {
            actions.add('pm disable $userFlag$pkg && echo -- Disabled $pkg');
          }
      } else if (state > 0 && !checked) {
        if (isUninstallable) {
          actions.add('pm uninstall $userFlag$pkg && echo -- Uninstalled $pkg');
        } else {
          actions.add('pm clear $userFlag$pkg && echo -- Cleared data from $pkg');
          if (pmSupportsDisableUser == true) {
            actions.add('pm disable-user $userFlag$pkg && echo -- Disabled $pkg');
          } else {
            actions.add('pm disable $userFlag$pkg && echo -- Disabled $pkg');
          }
        }
      } else if (state == 0 && checked) {
        actions.add('pm enable $userFlag$pkg && echo -- Enabled $pkg');
      } else if (state < 0 && checked) {
        if (pmSupportsInstallExisting == true) {
          actions.add('pm install-existing $userFlag$pkg && echo -- Installed $pkg');
        } else {
          actions.add('pm install -r $userFlag"$path" && echo -- Installed $path');
        }
      }
    });
    return actions;
  }

  static Future<bool> loadAppIcons(context, String iconsDirPath, String defaultIconPath) async {
    if (!await AdbService.ensureDevice(context)) {
      return false;
    }
    
    LoadingOverlay.show(context, 'Extracting icons...');
    await AdbService.runShell(
      'export CLASSPATH=/data/local/tmp/app_manager; app_process / Main -icon /data/local/tmp/icons',
      toLowerCase: false,
      toLogIfError: true
    );
    LoadingOverlay.hide();

    if (AdbService.hasError()) {
      Alert.showWarning(context, 'Failed to extract icons.\n\nSee log for details.');
      return false;
    }

    final iconsDir = Directory(iconsDirPath);

    if (await iconsDir.exists()) {
      await iconsDir.delete(recursive: true);
    }
    await iconsDir.create(recursive: true);

    LoadingOverlay.show(context, 'Pulling icons...');
    await AdbService.pullFile(
      '/data/local/tmp/icons/.',
      iconsDirPath
    );
    LoadingOverlay.hide();

    if (AdbService.hasError()) {
      Alert.showWarning(context, 'Failed to pull icons.\n\nSee log for details.');
      return false;
    }
    iconsLoaded = true;
    await assignIconPaths(iconsDirPath, defaultIconPath);
    return true;
  }

  static Future<void> assignIconPaths(String iconsDirPath, String defaultIconPath) async {
    for (final app in apps.values) {
      final iconFile = File('$iconsDirPath${app['package']}.png');
      if (await iconFile.exists()) {
        app['iconPath'] = iconFile.path;
      } else {
        app['iconPath'] = defaultIconPath;
      }
    }
  }

  static Future<bool> loadAppsFromDevice(BuildContext context) async {
    if (!await AdbService.ensureDevice(context)) {
      return false;
    }

    if (!await prepareAppManager(context)) {
      LoadingOverlay.hide();
      return false;
    }

    LoadingOverlay.show(context, 'Loading apps...');
    final output = await AdbService.runShell(
      'export CLASSPATH=/data/local/tmp/app_manager; app_process / Main',
      toLowerCase: false,
      toLogIfError: true
    );
    LoadingOverlay.hide();
    if (AdbService.hasError() || output.isEmpty) {
      Alert.showWarning(context, 'Failed to load app list.');
      return false;
    }

    parseAppManagerOutput(output);
    updateActionCounters();

    return true;
  }

  static void updateActionCounters() {
    int activate = 0, install = 0, deactivate = 0, uninstall = 0;
    final isUninstallable = !ConfigUtils.neverUninstallApps;
    apps.forEach((pkg, app) {
      final state = app['state'];
      final checked = app['isChecked'];
      final doBefore = app['doBefore'];
      if (doBefore == 'install-disable') deactivate++;
      else if (state > 0 && !checked) {
        if (isUninstallable) uninstall++;
        else deactivate++;
      }else if (state == 0 && checked) activate++;
      else if (state < 0 && checked) install++;
    });
    activateCount = activate;
    installCount = install;
    deactivateCount = deactivate;
    uninstallCount = uninstall;
  }

  static Future<void> applyChanges(BuildContext context) async {
    if (apps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No apps loaded.')),
      );
      return;
    }

    await setPMFlagSupport();

    final actions = buildActions();

    if (actions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No changes to apply.')),
      );
      return;
    }

    final shellCommand = AdbService.buildShellCommand(actions);

    LoadingOverlay.show(context, 'Applying changes...');
    final output = await AdbService.runShell(shellCommand);
    LoadingOverlay.hide();

    if (AdbService.hasError()) {
      Alert.showLog(context, output);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Commands executed successfully!')),
      );
    }

    final isUninstallable = !ConfigUtils.neverUninstallApps;

    apps.forEach((pkg, app) {
      final state = app['state'];
      final checked = app['isChecked'];
      final doBefore = app['doBefore'];
      if (doBefore == 'install-disable') {
        app['state'] = 0;
        app['isChecked'] = false;
        app['doBefore'] = null;
      } else if (state > 0 && !checked) {
        app['state'] = isUninstallable ? -1 : 0;
        app['isChecked'] = false;
      } else if (state == 0 && checked) {
        app['state'] = 1;
        app['isChecked'] = true;
      } else if (state < 0 && checked) {
        app['state'] = 1;
        app['isChecked'] = true;
      }
    });
    activateCount = 0;
    installCount = 0;
    uninstallCount = 0;
    deactivateCount = 0;
  }
}
