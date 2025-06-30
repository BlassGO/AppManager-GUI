import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_manager/utils/url.dart';
import 'package:app_manager/utils/file_manager.dart';
import 'package:animate_do/animate_do.dart';
import 'package:app_manager/utils/localization.dart';

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeIn(
                duration: const Duration(milliseconds: 300),
                child: Icon(Icons.nightlight_round, color: Colors.amber, size: 48),
              ),
              SizedBox(height: 12),
              FadeIn(
                duration: const Duration(milliseconds: 300),
                child: Text(
                  Localization.translate('device_offline_message'),
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        actions: [
          FadeIn(
            duration: const Duration(milliseconds: 300),
            child: TextButton(
              child: Text(Localization.translate('ok'), style: TextStyle(color: Colors.white, fontSize: 14)),
              onPressed: () => Navigator.of(context).pop(),
            ),
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
        SnackBar(content: Text(Localization.translate('failed_open_url'))),
      );
    }
  }

  bool _isHttpsUrl() {
    if (command == null || command!.isEmpty) return false;
    return command!.startsWith('https://') || command!.startsWith('http://');
  }

  bool _isAdbNotInstalled() {
    return message.contains(Localization.translate('adb_not_installed'));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      content: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FadeIn(
              duration: const Duration(milliseconds: 300),
              child: Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 48),
            ),
            SizedBox(height: 12),
            FadeIn(
              duration: const Duration(milliseconds: 300),
              child: Text(
                message,
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ),
            if (_isAdbNotInstalled()) ...[
              SizedBox(height: 16),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[700]!),
                ),
                padding: EdgeInsets.all(12),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.amber,
                            child: Text('1', style: TextStyle(color: Colors.black, fontSize: 14)),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  Localization.translate('adb_path_instruction'),
                                  style: TextStyle(color: Colors.white, fontSize: 14),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 12),
                                FadeIn(
                                  duration: const Duration(milliseconds: 300),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey[800],
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    onPressed: () => FileManager.selectAdbFolder(context),
                                    child: Text(Localization.translate('select_adb_folder'), style: TextStyle(fontSize: 14)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (command != null && command!.isNotEmpty) ...[
                        SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              radius: 12,
                              backgroundColor: Colors.amber,
                              child: Text('2', style: TextStyle(color: Colors.black, fontSize: 14)),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    Localization.translate('adb_install_instruction'),
                                    style: TextStyle(color: Colors.white, fontSize: 14),
                                    textAlign: TextAlign.left,
                                  ),
                                  SizedBox(height: 8),
                                  Row(
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
                                          FadeIn(
                                            duration: const Duration(milliseconds: 300),
                                            child: IconButton(
                                              tooltip: Localization.translate('copy'),
                                              icon: Icon(Icons.copy, color: Colors.white),
                                              onPressed: () {
                                                Clipboard.setData(ClipboardData(text: command!));
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text(Localization.translate('copied'))),
                                                );
                                              },
                                            ),
                                          ),
                                          if (_isHttpsUrl())
                                            FadeIn(
                                              duration: const Duration(milliseconds: 300),
                                              child: IconButton(
                                                tooltip: Localization.translate('open_in_browser'),
                                                icon: Icon(Icons.language, color: Colors.blueAccent),
                                                onPressed: () => _openInBrowser(context),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        FadeIn(
          duration: const Duration(milliseconds: 300),
          child: TextButton(
            child: Text(Localization.translate('close'), style: TextStyle(color: Colors.white, fontSize: 14)),
            onPressed: () => Navigator.of(context).pop(),
          ),
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final parentWidth = constraints.maxWidth;
        final parentHeight = constraints.maxHeight;
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          insetPadding: EdgeInsets.symmetric(
            horizontal: parentWidth * 0.1,
            vertical: parentHeight * 0.1,
          ),
          title: Row(
            children: [
              FadeIn(
                duration: const Duration(milliseconds: 300),
                child: Icon(Icons.article, color: Colors.cyanAccent),
              ),
              SizedBox(width: 8),
              FadeIn(
                duration: const Duration(milliseconds: 300),
                child: Text(Localization.translate('execution_log'), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              Spacer(),
              FadeIn(
                duration: const Duration(milliseconds: 300),
                child: IconButton(
                  tooltip: Localization.translate('copy'),
                  icon: Icon(Icons.copy, color: Colors.white),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: log));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(Localization.translate('log_copied'))),
                    );
                  },
                ),
              ),
            ],
          ),
          content: Container(
            width: parentWidth * 0.8,
            height: parentHeight * 0.8,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SingleChildScrollView(
              padding: EdgeInsets.all(12),
              child: FadeIn(
                duration: const Duration(milliseconds: 300),
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
          ),
          actions: [
            FadeIn(
              duration: const Duration(milliseconds: 300),
              child: TextButton(
                child: Text(Localization.translate('close'), style: TextStyle(color: Colors.white, fontSize: 14)),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        );
      },
    );
  }
}