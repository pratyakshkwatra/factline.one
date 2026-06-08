import 'package:factline/api/auth.dart';
import 'package:factline/api/models/user.dart';
import 'package:factline/services/translation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService extends ChangeNotifier {
  final AuthAPI _authAPI;
  final FlutterSecureStorage _secureStorage;

  static AuthService? _instance;
  factory AuthService(AuthAPI authAPI, FlutterSecureStorage secureStorage) {
    _instance ??= AuthService._internal(authAPI, secureStorage);
    return _instance!;
  }

  AuthService._internal(this._authAPI, this._secureStorage);

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  final ValueNotifier<String> languageNotifier = ValueNotifier('English');
  String _selectedLanguage = 'English';
  User? _user;

  User? get user => _user;

  String get selectedLanguage => _selectedLanguage;
  set selectedLanguage(String val) {
    _selectedLanguage = val;
    languageNotifier.value = val;
    TranslationService().setLanguage(val);
    _secureStorage.write(key: 'selected_language', value: val);
    notifyListeners();
  }

  Future<void> init() async {
    final token = await _secureStorage.read(key: _accessTokenKey);
    if (token != null) {
      try {
        _user = await _authAPI.getMe(token);
      } catch (_) {}
    }
    final lang = await _secureStorage.read(key: 'selected_language');
    if (lang != null) {
      _selectedLanguage = lang;
      languageNotifier.value = lang;
      TranslationService().setLanguage(lang);
    }
    notifyListeners();
  }

  Future<User?> login(String email, String password) async {
    try {
      final user = await _authAPI.signIn(email, password);
      _user = user;
      await _secureStorage.write(key: _accessTokenKey, value: user.accessToken);
      await _secureStorage.write(
        key: _refreshTokenKey,
        value: user.refreshToken,
      );
      notifyListeners();
      return user;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _secureStorage.delete(key: _accessTokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    _user = null;
    notifyListeners();
  }

  Future<String?> getAccessToken() async {
    return await _secureStorage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(key: _refreshTokenKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null;
  }

  Future<User?> initializeSession() async {
    return await _authAPI.refreshToken();
  }

  Future<void> register(String email, String password) async {
    try {
      await _authAPI.signUp(email, password);
    } catch (e) {
      rethrow;
    }
  }
}
