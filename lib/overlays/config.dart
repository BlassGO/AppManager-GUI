import 'package:flutter/material.dart';
import 'package:app_manager/services/adb.dart';
import 'package:app_manager/services/manager.dart';
import 'package:app_manager/overlays/alert.dart';
import 'package:app_manager/utils/config.dart';

class ConfigOverlay extends StatefulWidget {
  final VoidCallback? onConnect;
  final VoidCallback? refreshUI;
  const ConfigOverlay({this.onConnect, this.refreshUI, super.key});
  @override
  State<ConfigOverlay> createState() => _ConfigOverlayState();
}

class _ConfigOverlayState extends State<ConfigOverlay> {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController(text: '5555');
  bool _connecting = false;
  bool _disconnecting = false;

  @override
  void initState() {
    super.initState();
    _ipController.text = ConfigUtils.lastWirelessIp ?? '';
    _portController.text = ConfigUtils.lastWirelessPort ?? '5555';
  }

  Future<void> _connect() async {
    setState(() => _connecting = true);
    final ip = _ipController.text.trim();
    final port = _portController.text.trim();
    if (ip.isEmpty || port.isEmpty) {
      Alert.showWarning(context, 'Please enter both IP and port.');
      setState(() => _connecting = false);
      return;
    }
    ConfigUtils.lastWirelessIp = ip;
    ConfigUtils.lastWirelessPort = port;
    await ConfigUtils.save();
    final ok = await AdbService.connectTcp(ip, port);
    setState(() => _connecting = false);
    if (ok) {
      Navigator.of(context).pop();
      widget.onConnect?.call();
    } else {
      Alert.showWarning(
        context,
        'Could not connect to $ip:$port.\n\nMake sure the device is on the same network'
      );
    }
  }

  Future<void> _disconnect() async {
    final ip = _ipController.text.trim();
    final port = _portController.text.trim();
    setState(() => _disconnecting = true);
    final ok = await AdbService.disconnectTcp(ip, port);
    setState(() => _disconnecting = false);
    if (ok) {
      Navigator.of(context).pop();
    } else {
      Alert.showWarning(context, 'Could not disconnect. See log for details.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text('Settings', style: TextStyle(color: Colors.white)),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('OPTIONS', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(height: 8),
            Tooltip(
              message: 'Deactivate uninstallable apps and clear their data',
              child: CheckboxListTile(
                title: Text(
                  'Never uninstall, only deactivate',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                value: ConfigUtils.neverUninstallApps,
                onChanged: (value) {
                  setState(() {
                    ConfigUtils.neverUninstallApps = value ?? false;
                    ConfigUtils.save();
                    ManagerService.updateActionCounters();
                    widget.refreshUI?.call();
                  });
                },
                activeColor: Colors.blue,
                checkColor: Colors.white,
                tileColor: Colors.grey[800],
                contentPadding: EdgeInsets.symmetric(horizontal: 4),
                controlAffinity: ListTileControlAffinity.leading,
                checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                visualDensity: VisualDensity(horizontal: -2, vertical: -2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), 
              ),
            ),
            SizedBox(height: 8),
            Tooltip(
              message: 'Export all apps, even if there are no changes',
              child: CheckboxListTile(
                title: Text(
                  'Export all apps list',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                value: ConfigUtils.exportAllApps,
                onChanged: (value) {
                  setState(() {
                    ConfigUtils.exportAllApps = value ?? false;
                    ConfigUtils.save();
                  });
                },
                activeColor: Colors.blue,
                checkColor: Colors.white,
                tileColor: Colors.grey[800],
                contentPadding: EdgeInsets.symmetric(horizontal: 4),
                controlAffinity: ListTileControlAffinity.leading,
                checkboxShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                visualDensity: VisualDensity(horizontal: -2, vertical: -2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 12),
            Text('TCP/IP', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
            SizedBox(height: 8),
            TextField(
              controller: _ipController,
              decoration: InputDecoration(
                labelText: 'Device IP',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: 'e.g. 192.168.1.100',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _portController,
              decoration: InputDecoration(
                labelText: 'Port',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                hintText: 'e.g. 5555',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  icon: _connecting ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : Icon(Icons.wifi),
                  label: Text('Connect'),
                  onPressed: _connecting ? null : _connect,
                ),
                SizedBox(width: 16),
                ElevatedButton.icon(
                  icon: _disconnecting ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)) : Icon(Icons.link_off, color: Colors.red),
                  label: Text('Disconnect', style: TextStyle(color: Colors.red)),
                  onPressed: _disconnecting ? null : _disconnect,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Close', style: TextStyle(color: Colors.white)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}