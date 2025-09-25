import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TranslationService extends ChangeNotifier {
  static TranslationService? _instance;
  Map<String, dynamic>? _translations;
  Locale? _currentLocale;

  static TranslationService get instance {
    _instance ??= TranslationService._();
    return _instance!;
  }

  TranslationService._();

  /// Initialize the translation service with a specific locale
  Future<void> initialize(Locale locale) async {
    _currentLocale = locale;
    await _loadTranslations(locale.languageCode);
    notifyListeners();
  }

  /// Load translations from JSON file
  Future<void> _loadTranslations(String languageCode) async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/translation/$languageCode.json',
      );
      _translations = json.decode(jsonString);
    } catch (e) {
      // Fallback to English if translation file not found
      if (languageCode != 'en') {
        await _loadTranslations('en');
      } else {
        _translations = {};
      }
    }
  }

  /// Get translated text by key
  String tr(String key, {Map<String, String>? args}) {
    if (_translations == null) return key;

    String? translation = _getNestedValue(key);
    if (translation == null) return key;

    // Replace arguments if provided
    if (args != null) {
      args.forEach((placeholder, value) {
        translation = translation!.replaceAll('{$placeholder}', value);
      });
    }

    return translation!;
  }

  /// Get nested value from translations map
  String? _getNestedValue(String key) {
    final keys = key.split('.');
    dynamic current = _translations;

    for (final k in keys) {
      if (current is Map<String, dynamic> && current.containsKey(k)) {
        current = current[k];
      } else {
        return null;
      }
    }

    return current is String ? current : null;
  }

  /// Change language
  Future<void> changeLanguage(String languageCode) async {
    await initialize(Locale(languageCode));
  }

  /// Get current locale
  Locale? get currentLocale => _currentLocale;

  /// Check if a translation exists
  bool hasTranslation(String key) {
    return _getNestedValue(key) != null;
  }
}

/// Global translation function
String tr(String key, {Map<String, String>? args}) {
  return TranslationService.instance.tr(key, args: args);
}