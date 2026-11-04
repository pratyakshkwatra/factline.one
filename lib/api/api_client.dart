import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static String get _defaultBaseUrl {
    if (kIsWeb) return 'http://127.0.0.1:8000';
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    } catch (_) {}
    return 'http://127.0.0.1:8000';
  }

  ApiClient._internal() {
    _dio.options.baseUrl = _defaultBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          String? token;
          String lang = 'English';

          try {
            token = await _secureStorage.read(key: 'access_token');
            lang =
                await _secureStorage.read(key: 'selected_language') ??
                'English';
          } catch (_) {
            // Secure storage access error resilience
          }

          final Map<String, String> langMap = {
            'Hindi': 'hi',
            'Marathi': 'mr',
            'Tamil': 'ta',
            'Telugu': 'te',
            'Kannada': 'kn',
            'Gujarati': 'gu',
            'Bengali': 'bn',
            'Punjabi': 'pa',
            'Malayalam': 'ml',
            'Urdu': 'ur',
            'Spanish': 'es',
            'French': 'fr',
            'German': 'de',
            'Arabic': 'ar',
            'Turkish': 'tr',
            'Chinese': 'zh',
          };

          final langCode = langMap[lang] ?? 'en';

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Accept-Language'] = langCode;

          return handler.next(options);
        },
      ),
    );
  }

  Dio get dio => _dio;
}
