import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:app_manager/utils/config.dart';
import 'package:xml/xml.dart';

class Localization {
  static final Localization _instance = Localization._internal();
  static final ValueNotifier<String> languageNotifier = ValueNotifier('en');

  factory Localization() => _instance;
  Localization._internal();

  static Map<String, String>? _currentLocale;

  static Future<void> loadLanguages() async {
    try {
      final String languagesJson = await rootBundle.loadString('assets/languages.json');
      final List<dynamic> languages = jsonDecode(languagesJson);
      ConfigUtils.availableLanguages = {
        for (var lang in languages)
          (lang['file_name'] as String).replaceAll('.xml', ''): lang['name']
      };
    } catch (e) {
      ConfigUtils.availableLanguages = {'en': 'English'};
      throw Exception('Error loading available languages: $e. Defaulting to English.');
    }
  }

  static Future<void> loadLocale(String languageCode) async {
    try {
      final String xmlString = await rootBundle.loadString('assets/languages/$languageCode.xml');
      final document = XmlDocument.parse(xmlString);
      _currentLocale = {
        for (var element in document.findAllElements('translation'))
          element.getAttribute('key')!: element.text
      };
      ConfigUtils.currentLanguage = languageCode;
      await ConfigUtils.save();
      languageNotifier.value = languageCode;
    } catch (e) {
      _currentLocale = await _loadDefaultLocale();
      ConfigUtils.currentLanguage = 'en';
      await ConfigUtils.save();
      languageNotifier.value = 'en';
      throw Exception('Error loading language "$languageCode": $e. Falling back to default English locale.');
    }
  }

  static Future<Map<String, String>> _loadDefaultLocale() async {
    try {
      final String xmlString = await rootBundle.loadString('assets/languages/en.xml');
      final document = XmlDocument.parse(xmlString);
      return {
        for (var element in document.findAllElements('translation'))
          element.getAttribute('key')!: element.text
      };
    } catch (e) {
      throw Exception('Critical error: Could not load default English locale: $e');
    }
  }

  static String translate(String key) {
    return _currentLocale?[key] ?? key;
  }
}