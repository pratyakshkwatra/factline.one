import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:translator/translator.dart';

class TranslationService extends ChangeNotifier {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  final _storage = const FlutterSecureStorage();
  final _translator = GoogleTranslator();

  String _currentLanguage = 'English';
  Map<String, Map<String, String>> _dynamicCache = {};

  Future<void> init() async {
    final cached = await _storage.read(key: 'translation_dynamic_cache');
    if (cached != null) {
      try {
        final decoded = jsonDecode(cached) as Map<String, dynamic>;
        _dynamicCache = decoded.map(
          (k, v) => MapEntry(k, Map<String, String>.from(v as Map)),
        );
      } catch (_) {}
    }
  }

  void setLanguage(String lang) {
    if (_currentLanguage == lang) return;
    _currentLanguage = lang;
    notifyListeners();
  }

  String get currentLanguage => _currentLanguage;

  String translate(String text) {
    if (_currentLanguage == 'English') return text;

    final key = text.trim();
    if (_dynamicCache.containsKey(_currentLanguage)) {
      final cachedVal = _dynamicCache[_currentLanguage]![key];
      if (cachedVal != null) return cachedVal;
    }

    _triggerBackgroundTranslation(key);

    return text;
  }

  void _triggerBackgroundTranslation(String key) async {
    await translateAsync(key);
  }

  Future<String> translateAsync(String text) async {
    if (_currentLanguage == 'English') return text;

    final key = text.trim();
    final langCode = _getLangCode(_currentLanguage);

    if (_dynamicCache[_currentLanguage]?.containsKey(key) ?? false) {
      return _dynamicCache[_currentLanguage]![key]!;
    }

    try {
      final translation = await _translator.translate(key, to: langCode);
      final translatedText = translation.text;

      _dynamicCache[_currentLanguage] ??= {};
      _dynamicCache[_currentLanguage]![key] = translatedText;

      await _storage.write(
        key: 'translation_dynamic_cache',
        value: jsonEncode(_dynamicCache),
      );

      notifyListeners();
      return translatedText;
    } catch (e) {
      debugPrint("Translation Error for '$key': $e");
      return text;
    }
  }

  String _getLangCode(String name) {
    switch (name) {
      case 'Hindi':
        return 'hi';
      case 'Spanish':
        return 'es';
      case 'French':
        return 'fr';
      case 'German':
        return 'de';
      case 'Marathi':
        return 'mr';
      case 'Tamil':
        return 'ta';
      case 'Telugu':
        return 'te';
      case 'Kannada':
        return 'kn';
      case 'Gujarati':
        return 'gu';
      case 'Bengali':
        return 'bn';
      case 'Punjabi':
        return 'pa';
      case 'Malayalam':
        return 'ml';
      case 'Urdu':
        return 'ur';
      case 'Arabic':
        return 'ar';
      case 'Turkish':
        return 'tr';
      case 'Chinese':
        return 'zh';
      case 'Italian':
        return 'it';
      case 'Portuguese':
        return 'pt';
      case 'Russian':
        return 'ru';
      case 'Japanese':
        return 'ja';
      case 'Korean':
        return 'ko';
      case 'Vietnamese':
        return 'vi';
      case 'Thai':
        return 'th';
      case 'Indonesian':
        return 'id';
      default:
        return 'en';
    }
  }
}

extension TranslationExtension on String {
  String get tr => TranslationService().translate(this);
}
