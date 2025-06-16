import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_manager/utils/url.dart';

class Alert {
  static void showWarning(BuildContext context, String message, {String? command}) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _WarningDialog(message: message, command: command),
    );
  }

  static void showLog(BuildContext context, String log) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _LogDialog(log: log),
    );
  }

  static Future<void> showDeviceOffline(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.nightlight_round, color: Colors.amber, size: 48),
            SizedBox(height: 12),
            Text(
              'Device is offline.\n\nPlease turn on the device screen and unlock it.',
              style: TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text('OK', style: TextStyle(color: Colors.white)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _WarningDialog extends StatelessWidget {
  final String message;
  final String? command;

  const _WarningDialog({required this.message, this.command});

  Future<void> _openInBrowser(BuildContext context) async {
    if (command == null || command!.isEmpty) return;

    final success = await UrlUtils.trylaunchUrl(command!);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to open URL in browser.')),
      );
    }
  }

  bool _isHttpsUrl() {
    if (command == null || command!.isEmpty) return false;
    return command!.startsWith('https://') || command!.startsWith('http://');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 48),
          SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.white, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          if (command != null && command!.isNotEmpty) ...[
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[700]!),
              ),
              padding: EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: SelectableText(
                      command!,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Colors.greenAccent,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      IconButton(
                        tooltip: 'Copy',
                        icon: Icon(Icons.copy, color: Colors.white),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: command!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Copied!')),
                          );
                        },
                      ),
                      if (_isHttpsUrl())
                        IconButton(
                          tooltip: 'Open in Browser',
                          icon: Icon(Icons.language, color: Colors.blueAccent),
                          onPressed: () => _openInBrowser(context),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
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

class _LogDialog extends StatelessWidget {
  final String log;

  const _LogDialog({required this.log});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      title: Row(
        children: [
          Icon(Icons.article, color: Colors.cyanAccent),
          SizedBox(width: 8),
          Text('Execution Log', style: TextStyle(color: Colors.white)),
          Spacer(),
          IconButton(
            tooltip: 'Copy',
            icon: Icon(Icons.copy, color: Colors.white),
            onPressed: () {
              Clipboard.setData(ClipboardData(text: log));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Log copied!')),
              );
            },
          ),
        ],
      ),
      content: Container(
        width: 500,
        height: 300,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
        ),
        child: SingleChildScrollView(
          child: SelectableText(
            log,
            style: TextStyle(
              fontFamily: 'monospace',
              color: Colors.white,
              fontSize: 13,
            ),
          ),
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