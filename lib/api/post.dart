import 'package:dio/dio.dart';
import 'package:factline/api/models/post.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';
import 'exceptions.dart';

class PostAPI {
  final _dio = ApiClient().dio;
  final _storage = const FlutterSecureStorage();

  Future<String> uploadMedia(String filePath) async {
    try {
      final String fileName = filePath.split('/').last;
      final FormData formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(filePath, filename: fileName),
      });

      final response = await _dio.post('/posts/upload', data: formData);

      return response.data["url"];
    } on DioException catch (e) {
      throw APIException(
        e.message ?? 'Failed to upload media',
        e.response?.statusCode,
      );
    }
  }

  Future<AnalysisStatusUpdate> getAnalysisStatus(int postId) async {
    try {
      final accessToken = await _storage.read(key: 'access_token');
      if (accessToken == null) throw APIException('Not authenticated', 401);

      final response = await _dio.get(
        '/posts/$postId/status',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      return AnalysisStatusUpdate.fromJson(response.data);
    } on DioException catch (e) {
      throw APIException(
        e.message ?? 'Failed to get analysis status',
        e.response?.statusCode,
      );
    }
  }

  Future<Post> createPost({
    required String title,
    String? body,
    String? mediaUrl,
    String mediaType = "TEXT",
    String? sourceUrl,
  }) async {
    try {
      final accessToken = await _storage.read(key: 'access_token');
      if (accessToken == null) {
        throw APIException('Not authenticated', 401);
      }

      final response = await _dio.post(
        '/posts/',
        data: {
          'title': title,
          'body': body,
          'media_url': mediaUrl,
          'media_type': mediaType,
          'source_url': sourceUrl,
        },
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );

      return Post.fromJson(response.data);
    } on DioException catch (e) {
      throw APIException(
        e.message ?? 'Failed to create post',
        e.response?.statusCode,
      );
    }
  }

  Future<void> deletePost(int postId) async {
    try {
      final accessToken = await _storage.read(key: 'access_token');
      if (accessToken == null) {
        throw APIException('Not authenticated', 401);
      }

      await _dio.delete(
        '/posts/$postId',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } on DioException catch (e) {
      throw APIException(
        e.message ?? 'Failed to delete post',
        e.response?.statusCode,
      );
    }
  }

  Future<void> upvotePost(int postId) async {
    try {
      final accessToken = await _storage.read(key: 'access_token');
      if (accessToken == null) throw APIException('Not authenticated', 401);

      await _dio.post(
        '/posts/$postId/upvote',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } on DioException catch (e) {
      throw APIException(
        e.message ?? 'Failed to upvote post',
        e.response?.statusCode,
      );
    }
  }

  Future<void> downvotePost(int postId) async {
    try {
      final accessToken = await _storage.read(key: 'access_token');
      if (accessToken == null) throw APIException('Not authenticated', 401);

      await _dio.post(
        '/posts/$postId/downvote',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } on DioException catch (e) {
      throw APIException(
        e.message ?? 'Failed to downvote post',
        e.response?.statusCode,
      );
    }
  }

  Future<void> viewPost(int postId) async {
    try {
      final accessToken = await _storage.read(key: 'access_token');
      if (accessToken == null) throw APIException('Not authenticated', 401);

      await _dio.post(
        '/posts/$postId/view',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
    } on DioException catch (e) {
      throw APIException(
        e.message ?? 'Failed to record view',
        e.response?.statusCode,
      );
    }
  }

  Future<List<Post>> getMyPosts() async {
    try {
      final response = await _dio.get('/posts/me');
      return (response.data as List).map((p) => Post.fromJson(p)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<List<Post>> getRecommendations() async {
    try {
      final accessToken = await _storage.read(key: 'access_token');
      if (accessToken == null) throw APIException('Not authenticated', 401);

      final response = await _dio.get(
        '/posts/recommendations',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      final List data = response.data;

      return data.map((json) => Post.fromJson(json)).toList();
    } on DioException catch (e) {
      throw APIException(
        e.message ?? 'Failed to load recommendations',
        e.response?.statusCode,
      );
    }
  }

  Future<List<Post>> getBreakingNews() async {
    try {
      final accessToken = await _storage.read(key: 'access_token');
      if (accessToken == null) throw APIException('Not authenticated', 401);

      final response = await _dio.get(
        '/posts/breaking-news',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      final List data = response.data;

      return data.map((json) => Post.fromJson(json)).toList();
    } on DioException catch (e) {
      throw APIException(
        e.message ?? 'Failed to load breaking news',
        e.response?.statusCode,
      );
    }
  }

  Future<List<PostPin>> getMapPins() async {
    try {
      final accessToken = await _storage.read(key: 'access_token');
      final response = await _dio.get(
        '/posts/map/pins',
        options: accessToken != null
            ? Options(headers: {'Authorization': 'Bearer $accessToken'})
            : null,
      );
      final List data = response.data;

      return data.map((json) => PostPin.fromJson(json)).toList();
    } on DioException catch (e) {
      throw APIException(
        e.message ?? 'Failed to load map pins',
        e.response?.statusCode,
      );
    }
  }

  Future<Post?> getPostDetail(int postId) async {
    try {
      final accessToken = await _storage.read(key: 'access_token');
      final response = await _dio.get(
        '/posts/$postId',
        options: accessToken != null
            ? Options(headers: {'Authorization': 'Bearer $accessToken'})
            : null,
      );
      return Post.fromJson(response.data);
    } on DioException catch (e) {
      throw APIException(
        e.message ?? 'Failed to load post details',
        e.response?.statusCode,
      );
    }
  }
}
