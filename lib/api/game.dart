import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';
import 'exceptions.dart';
import 'models/game.dart';

class GameAPI {
  final _dio = ApiClient().dio;
  final _storage = const FlutterSecureStorage();

  Future<GameArticle> generateGameArticle(GameQuery query) async {
    try {
      final accessToken = await _storage.read(key: 'access_token');
      if (accessToken == null) throw APIException('Not authenticated', 401);

      final response = await _dio.post(
        '/game/generate',
        data: query.toJson(),
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      return GameArticle.fromJson(response.data);
    } on DioException catch (e) {
      throw APIException(
        e.message ?? 'Failed to generate game article',
        e.response?.statusCode,
      );
    }
  }
}
