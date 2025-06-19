import 'dart:io';
import 'dart:convert';
import 'package:app_manager/services/manager.dart';
import 'package:flutter/material.dart';
import 'package:app_manager/models/device_info.dart';
import 'package:app_manager/overlays/adb.dart';
import 'package:app_manager/overlays/load.dart';
import 'package:app_manager/overlays/alert.dart';
import 'package:app_manager/utils/config.dart';

class AdbService {
  static final StringBuffer _logBuffer = StringBuffer();
  static String? lastWirelessIp;
  static String? lastWirelessPort;
  static int? lastExitCode;
  static DeviceInfo? currentDevice;
  static bool _adbInitialized = false;
  static bool _isAdbAvailable = false;

  static String? get lastLog => _logBuffer.toString();

  static void appendLog(String? value) {
    if (value == null || value.isEmpty) return;
    _logBuffer.writeln(value);
  }

  static void clearLog() {
    _logBuffer.clear();
  }

  static void reset() {
    currentDevice = null;
    clearLog();
    lastExitCode = null;
    ManagerService.reset();
  }

  static Future<bool> isAdbAvailable() async {
    if (_isAdbAvailable) return true;
    await runAdb(['version']);
    _isAdbAvailable = !hasError();
    return _isAdbAvailable;
  }

  static Future<String> runAdb(List<String> args, {bool toLog = true, bool toLogIfError = false, bool toLowerCase = true, int exitCode = 0}) async {
    try {
      final result = await Process.run(
        'adb',
        _withSerial(args),
        stdoutEncoding: utf8,
        stderrEncoding: utf8,
      );
      final output = ((result.stdout ?? '').toString() + (result.stderr ?? '').toString());
      final lower = output.toLowerCase();
      setErrorCode(result.exitCode, lower);
      if ((toLogIfError && hasError()) || (!toLogIfError && toLog)) appendLog(output);
      return toLowerCase ? lower : output;
    } catch (e) {
      appendLog('ADB Exception: $e');
      setErrorCode(1, '');
      return '';
    }
  }

  static Future<void> runAdbStream(
    List<String> args, {
    required Function(String) onLineReceived,
    bool toLog = true,
    bool toLogIfError = false
  }) async {
    try {
      final process = await Process.start('adb', _withSerial(args));
      bool hasError = false;

      await for (var line in process.stdout.transform(utf8.decoder).transform(const LineSplitter())) {
        if (line.trim().isEmpty) continue;
        if (toLog) appendLog(line);
        onLineReceived(line);
      }

      await for (var line in process.stderr.transform(utf8.decoder).transform(const LineSplitter())) {
        if (toLogIfError) appendLog(line);
        hasError = true;
      }

      final exitCode = await process.exitCode;
      setErrorCode(exitCode, hasError ? 'error' : '');
    } catch (e) {
      appendLog('ADB Exception: $e');
      setErrorCode(1, '');
    }
  }

  static void setErrorCode(int exitCode, String output) {
    lastExitCode = exitCode;
    if (lastExitCode == 0) {
      lastExitCode = RegExp(r'\b(error|failure)\b').hasMatch(output) ? 1 : 0;
    }
  }

  static Future<List<DeviceInfo>> findDevices() async {
    var output = await runAdb(['devices', '-l'], toLowerCase: false, toLogIfError: true);
    List<DeviceInfo> devices = _parseDevicesOutput(output);

    if (devices.isEmpty && !_adbInitialized) {
      await initAdb();
      _adbInitialized = true;
      output = await runAdb(['devices', '-l'], toLowerCase: false);
      devices = _parseDevicesOutput(output);
    } else {
      _adbInitialized = true;
    }
    return devices;
  }

  static List<DeviceInfo> _parseDevicesOutput(String output) {
    final lines = output.split(RegExp(r'[\r\n]+'));
    List<DeviceInfo> devices = [];
    int serialN = 0;
    for (final line in lines) {
      if (line.contains('List of')) continue;
      if (line.trim().isEmpty) continue;
      final wifiMatch = RegExp(r'^((\d{1,3}\.){3}\d{1,3}:\d+?)(?=[ \t])').firstMatch(line);
      String? serial;
      if (wifiMatch != null) {
        serial = wifiMatch.group(1);
      } else {
        final serialMatch = RegExp(r'^([a-zA-Z]*[0-9][a-zA-Z0-9]+?)(?=[ \t])').firstMatch(line);
        if (serialMatch != null) {
          serial = serialMatch.group(1);
        }
      }
      if (serial != null) {
        serialN++;
        String name = '';
        final modelMatch = RegExp(r'model:(\S+)').firstMatch(line);
        if (modelMatch != null) {
          name = modelMatch.group(1)!;
        } else {
          final productMatch = RegExp(r'(device product|device):(\S+)').firstMatch(line);
          if (productMatch != null) {
            name = productMatch.group(2)!;
          } else {
            name = 'Device $serialN';
          }
        }
        final isActive = !(line.contains('offline') || line.contains('unauthorized'));
        final connection = RegExp(r'^((\d{1,3}\.){3}\d{1,3}:\d+?)(?=[ \t])').hasMatch(line) ? 'WIFI' : 'USB';
        devices.add(DeviceInfo(
          name: name,
          serial: serial,
          connection: connection,
          isActive: isActive,
        ));
      }
    }
    return devices;
  }

  static List<String> _withSerial(List<String> args) {
    if (currentDevice != null && currentDevice!.serial.isNotEmpty) {
      return ['-s', currentDevice!.serial, ...args];
    }
    return args;
  }

  static Future<String> pushFile(String localPath, String remotePath) async {
    return await runAdb(['push', localPath, remotePath], toLogIfError: true);
  }

  static Future<String> pullFile(String remotePath, String localPath) async {
    return await runAdb(['pull', remotePath, localPath], toLogIfError: true);
  }

  static Future<String> runShell(String shellCommand, {toLog = true, toLogIfError = false, toLowerCase = true}) async {
    return await runAdb(['shell', shellCommand], toLog: toLog, toLogIfError: toLogIfError, toLowerCase: toLowerCase);
  }

  static String getInstallCommand() {
    if (Platform.isLinux) {
      return 'sudo apt install android-tools-adb';
    } else if (Platform.isMacOS) {
      return 'brew install android-platform-tools';
    } else {
      return 'https://developer.android.com/tools/releases/platform-tools';
    }
  }

  static bool hasError() {
    return lastExitCode != 0;
  }

  static String buildShellCommand(List<String> actions) {
    return actions.join(' ; ');
  }

  static Future<bool> initAdb() async {
    var output = await runAdb(['start-server']);
    if (output.contains('daemon started successfully')) {
      return true;
    } else {
      // Try to reset the server
      await runAdb(['kill-server']);
      output = await runAdb(['start-server']);
      return output.contains('daemon started successfully');
    }
  }

  static Future<bool> connectTcp(String ip, String port) async {
    currentDevice = null;
    final output = await runAdb(['connect', '$ip:$port']);
    if (output.contains('connected') || output.contains('already connected')) {
      ConfigUtils.lastWirelessIp = ip;
      ConfigUtils.lastWirelessPort = port;
      ConfigUtils.useWireless = true;
      await ConfigUtils.save();
      return true;
    }
    return false;
  }

  static Future<bool> disconnectTcp(String ip, String port) async {
    await runAdb(['disconnect', '$ip:$port']);
    if (currentDevice != null && currentDevice!.connection == 'WIFI') {
      currentDevice = null;
      ConfigUtils.useWireless = false;
    }
    return !hasError();
  }

  static Future<bool> isOnline() async {
    if (currentDevice == null) return false;
    final output = await runAdb(['get-state'], toLog: false);
    return output.trim() == 'device';
  }

  static Future<bool> selectDevice(BuildContext context, {showSelector = false, Future<void> Function()? loadAppsCallback}) async {
    if (!await isAdbAvailable()) {
      Alert.showWarning(context, 'ADB is not installed.\n\nSuggested action:', command: getInstallCommand());
      return false;
    }

    bool isNewDevice = false;
    DeviceInfo? selectedDevice;
    final devices = await findDevices();

    if (showSelector || devices.length > 1) {
      LoadingOverlay.hide();
      selectedDevice = await AdbOverlay.showDeviceSelector(context, devices);
    } else if (devices.isNotEmpty) {
      selectedDevice = devices.first;
    }

    if (selectedDevice != null) {
      isNewDevice = (selectedDevice.serial != currentDevice?.serial);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Device selected: ${selectedDevice.name}')),
      );
      if (isNewDevice) {
        reset();
        currentDevice = selectedDevice;
        if (showSelector && loadAppsCallback != null) {
          await loadAppsCallback();
        }
      }
    }

    return isNewDevice;
  }

  static Future<bool> ensureDevice(context) async {
    if (currentDevice == null) {
      if (!await isAdbAvailable()) {
        Alert.showWarning(context,'ADB is not installed.\n\nSuggested action:', command: getInstallCommand());
        return false;
      }
      //LoadingOverlay.show(context, 'Finding devices...');
      if (ConfigUtils.useWireless && ConfigUtils.lastWirelessIp != null && ConfigUtils.lastWirelessPort != null) {
        await connectTcp(ConfigUtils.lastWirelessIp!, ConfigUtils.lastWirelessPort!);
      }
      if (!await selectDevice(context)) {
        //LoadingOverlay.hide();
        Alert.showWarning(context, 'No devices found. Please connect a device.');
        return false;
      }
      //LoadingOverlay.hide();
    }
    final output = await runAdb(['get-state'], toLog: false);
    if (output.contains('offline')) {
      await Alert.showDeviceOffline(context);
      if (!await isOnline()) {
        currentDevice = null;
        return false;
      }
      return true;
    } else if (output.contains('unauthorized')) {
      appendLog(output);
      Alert.showWarning(
        context,
        'Device is unauthorized. Please allow USB debugging on the device.',
      );
      currentDevice = null;
      return false;
    } else if (output.contains('device')) {
      return true;
    }
    return false;
  }
}