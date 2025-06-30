import 'package:flutter/material.dart';
import 'package:app_manager/overlays/alert.dart';
import 'package:app_manager/utils/localization.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlUtils {
  static Future<bool> trylaunchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  static void launchUrlOrShow(BuildContext context, String url) async {
    final success = await trylaunchUrl(url);
    if (!success) {
      Alert.showWarning(
        context,
        Localization.translate('could_not_open_url'),
        command: url,
      );
    }
  }
}