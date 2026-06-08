import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ApiClient._internal() {
    _dio.options.baseUrl = 'http://127.0.0.1:8000';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: 'access_token');
          final lang =
              await _secureStorage.read(key: 'selected_language') ?? 'English';

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

          if (token != null) {
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
