import 'package:flutter/material.dart';
import 'package:app_manager/models/device_info.dart';

class AdbOverlay {
  static Future<DeviceInfo?> showDeviceSelector(BuildContext context, List<DeviceInfo> devices) async {
    return await showDialog<DeviceInfo>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DeviceSelectorDialog(devices: devices),
    );
  }
}

class _DeviceSelectorDialog extends StatelessWidget {
  final List<DeviceInfo> devices;

  const _DeviceSelectorDialog({required this.devices});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Text('Select Device', style: TextStyle(color: Colors.white)),
      content: Container(
        width: 500,
        height: 60.0 + devices.length * 56.0,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(Colors.blueGrey[800]),
              columns: const [
                DataColumn(label: Text('Action', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Name', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Connection', style: TextStyle(color: Colors.white))),
                DataColumn(label: Text('Serial', style: TextStyle(color: Colors.white))),
              ],
              rows: devices.map((device) {
                return DataRow(
                  cells: [
                    DataCell(
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(device),
                        child: Text('Select'),
                      ),
                    ),
                    DataCell(Text(device.name, style: TextStyle(color: Colors.white))),
                    DataCell(
                      Row(
                        children: [
                          Icon(
                            device.isActive ? Icons.check_circle : Icons.cancel,
                            color: device.isActive ? Colors.greenAccent : Colors.redAccent,
                            size: 18,
                          ),
                          SizedBox(width: 4),
                          Text(
                            device.connection,
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Container(
                        constraints: BoxConstraints(maxWidth: 200),
                        child: Text(
                          device.serial,
                          style: TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancel', style: TextStyle(color: Colors.white)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}