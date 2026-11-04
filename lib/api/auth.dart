import 'package:dio/dio.dart';
import 'package:factline/api/models/user.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';
import 'exceptions.dart';

class AuthAPI {
  final _dio = ApiClient().dio;
  final _storage = const FlutterSecureStorage();

  String _extractErrorMessage(DioException e, [String fallback = 'An Error Occurred']) {
    if (e.response?.data is Map) {
      final detail = e.response!.data['detail'];
      if (detail != null) {
        if (detail is String) return detail;
        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map && first['msg'] != null) return first['msg'].toString();
        }
        return detail.toString();
      }
      final msg = e.response!.data['message'];
      if (msg != null) return msg.toString();
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Cannot reach backend server. Please check your connection.';
    }
    return e.message ?? fallback;
  }

  Future<User> signIn(String email, String password) async {
    try {
      final response = await _dio.post(
        '/auth/sign_in',
        data: {'email': email, 'password': password},
      );

      final data = response.data;
      final user = User.fromJson(data);

      if (user.accessToken != null) {
        await _storage.write(key: 'access_token', value: user.accessToken);
      }
      if (user.refreshToken != null) {
        await _storage.write(key: 'refresh_token', value: user.refreshToken);
      }

      return user;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401) {
        throw APIException('Invalid credentials', 401);
      }

      throw APIException(
        _extractErrorMessage(e, 'Sign in failed'),
        statusCode,
      );
    } catch (e) {
      if (e is APIException) rethrow;
      throw APIException(e.toString());
    }
  }

  Future<void> signUp(String email, String password) async {
    try {
      await _dio.post(
        '/auth/sign_up',
        data: {'email': email, 'password': password},
      );
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 400) {
        throw APIException('Email already exists', 400);
      }
      throw APIException(
        _extractErrorMessage(e, 'Registration failed'),
        statusCode,
      );
    } catch (e) {
      if (e is APIException) rethrow;
      throw APIException(e.toString());
    }
  }

  Future<User?> refreshToken() async {
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (refreshToken == null) return null;

    try {
      final res = await _dio.post(
        '/auth/refresh_token',
        data: {'refresh_token': refreshToken},
      );
      if (res.data is Map && res.data['access_token'] != null) {
        await _storage.write(
          key: 'access_token',
          value: res.data['access_token'],
        );
      }
      return User.fromJson(res.data);
    } catch (error) {
      await _storage.deleteAll();
      return null;
    }
  }

  Future<void> logout(String refreshToken, String accessToken) async {
    try {
      await _dio.post(
        '/auth/sign_out',
        queryParameters: {
          'refresh_token': refreshToken,
          "access_token": accessToken,
        },
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } catch (_) {}
    await _storage.deleteAll();
  }

  Future<User> getMe(String accessToken) async {
    try {
      final response = await _dio.get(
        '/auth/me',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      return User.fromJson(response.data);
    } on DioException catch (e) {
      throw APIException(
        _extractErrorMessage(e, 'Session expired'),
        e.response?.statusCode,
      );
    } catch (e) {
      if (e is APIException) rethrow;
      throw APIException(e.toString());
    }
  }
}
