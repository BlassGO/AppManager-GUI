import 'package:flutter/material.dart';
import 'package:app_manager/models/device_info.dart';
import 'package:animate_do/animate_do.dart';
import 'package:app_manager/utils/localization.dart';

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: EdgeInsets.symmetric(
            horizontal: parentWidth * 0.1,
            vertical: parentHeight * 0.1,
          ),
          title: FadeIn(
            duration: const Duration(milliseconds: 300),
            child: Text(Localization.translate('select_device'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20)),
          ),
          content: SizedBox(
            width: parentWidth * 0.8,
            height: parentHeight * 0.8,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SingleChildScrollView(
                child: Card(
                  elevation: 2.0,
                  color: Colors.grey[850],
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(Colors.blueGrey[800]),
                    columnSpacing: 16,
                    columns: [
                      DataColumn(
                        label: Container(
                          constraints: BoxConstraints(
                            minWidth: tableWidth * 0.2,
                            maxWidth: tableWidth * 0.25,
                          ),
                          child: Text(
                            Localization.translate('action'),
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
                            Localization.translate('name'),
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
                            Localization.translate('connection'),
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
                            Localization.translate('serial'),
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
                              child: FadeIn(
                                duration: const Duration(milliseconds: 300),
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () => Navigator.of(context).pop(device),
                                  child: Text(Localization.translate('select'), style: TextStyle(fontSize: 14)),
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              constraints: BoxConstraints(
                                minWidth: tableWidth * 0.3,
                                maxWidth: tableWidth * 0.35,
                              ),
                              child: FadeIn(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  device.name,
                                  style: TextStyle(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                          ),
                          DataCell(
                            Container(
                              constraints: BoxConstraints(
                                minWidth: tableWidth * 0.3,
                                maxWidth: tableWidth * 0.35,
                              ),
                              child: FadeIn(
                                duration: const Duration(milliseconds: 300),
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
                          ),
                          DataCell(
                            Container(
                              constraints: BoxConstraints(
                                minWidth: tableWidth * 0.2,
                                maxWidth: tableWidth * 0.25,
                              ),
                              child: FadeIn(
                                duration: const Duration(milliseconds: 300),
                                child: Text(
                                  device.serial,
                                  style: TextStyle(color: Colors.white),
                                  overflow: TextOverflow.ellipsis,
                                ),
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
          ),
          actions: [
            FadeIn(
              duration: const Duration(milliseconds: 300),
              child: TextButton(
                child: Text(Localization.translate('cancel'), style: TextStyle(color: Colors.white, fontSize: 14)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        );
      },
    );
  }
}