import 'package:flutter/material.dart';
import 'package:app_manager/overlays/alert.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlUtils {
  static void launchUrlOrShow(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      Alert.showWarning(context, 'Could not open the URL\n\nUse this link:', command: url);
    }
  }
}