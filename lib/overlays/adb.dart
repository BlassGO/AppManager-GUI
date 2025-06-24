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
    return LayoutBuilder(
      builder: (context, constraints) {
        final parentWidth = constraints.maxWidth;
        final parentHeight = constraints.maxHeight;
        final tableWidth = parentWidth * 0.65;
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          insetPadding: EdgeInsets.symmetric(
            horizontal: parentWidth * 0.1,
            vertical: parentHeight * 0.1,
          ),
          title: Text('Select Device', style: TextStyle(color: Colors.white)),
          content: Container(
            width: parentWidth * 0.8,
            height: parentHeight * 0.8,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(Colors.blueGrey[800]),
                  columnSpacing: 16,
                  columns: [
                    DataColumn(
                      label: Container(
                        constraints: BoxConstraints(
                          minWidth: tableWidth * 0.2,
                          maxWidth: tableWidth * 0.25,
                        ),
                        child: Text(
                          'Action',
                          style: TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Container(
                        constraints: BoxConstraints(
                          minWidth: tableWidth * 0.3,
                          maxWidth: tableWidth * 0.35,
                        ),
                        child: Text(
                          'Name',
                          style: TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Container(
                        constraints: BoxConstraints(
                          minWidth: tableWidth * 0.3,
                          maxWidth: tableWidth * 0.35,
                        ),
                        child: Text(
                          'Connection',
                          style: TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataColumn(
                      label: Container(
                        constraints: BoxConstraints(
                          minWidth: tableWidth * 0.2,
                          maxWidth: tableWidth * 0.25,
                        ),
                        child: Text(
                          'Serial',
                          style: TextStyle(color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                  rows: devices.map((device) {
                    return DataRow(
                      cells: [
                        DataCell(
                          Container(
                            constraints: BoxConstraints(
                              minWidth: tableWidth * 0.2,
                              maxWidth: tableWidth * 0.25,
                            ),
                            child: ElevatedButton(
                              onPressed: () => Navigator.of(context).pop(device),
                              child: Text('Select'),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            constraints: BoxConstraints(
                              minWidth: tableWidth * 0.3,
                              maxWidth: tableWidth * 0.35,
                            ),
                            child: Text(
                              device.name,
                              style: TextStyle(color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            constraints: BoxConstraints(
                              minWidth: tableWidth * 0.3,
                              maxWidth: tableWidth * 0.35,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  device.isActive ? Icons.check_circle : Icons.cancel,
                                  color: device.isActive ? Colors.greenAccent : Colors.redAccent,
                                  size: 18,
                                ),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    device.connection,
                                    style: TextStyle(color: Colors.white),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            constraints: BoxConstraints(
                              minWidth: tableWidth * 0.2,
                              maxWidth: tableWidth * 0.25,
                            ),
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
      },
    );
  }
}