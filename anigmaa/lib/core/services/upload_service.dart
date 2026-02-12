import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_config.dart';
import '../utils/app_logger.dart';

/// Service for uploading images to the backend
class UploadService {
  static final UploadService _instance = UploadService._internal();
  factory UploadService() => _instance;
  UploadService._internal();

  final Dio _dio = Dio();
  static const _secureStorage = FlutterSecureStorage();

  /// Upload a single image file
  ///
  /// Returns the URL of the uploaded image
  /// Throws [Exception] if upload fails
  Future<String> uploadImage(File imageFile) async {
    try {
      // Get auth token from secure storage (key is 'access_token' not 'auth_token')
      final token = await _secureStorage.read(key: 'access_token');

      if (token == null || token.isEmpty) {
        throw Exception('No authentication token found. Please login first.');
      }

      // Use AppConfig.baseUrl which handles Android emulator + Docker WSL mapping
      // For Android emulator: localhost → 10.0.2.2
      _dio.options.baseUrl = AppConfig.apiUrl;  // apiUrl already includes /api/v1
      _dio.options.connectTimeout = const Duration(seconds: 30);
      _dio.options.receiveTimeout = const Duration(seconds: 30);
      _dio.options.headers['Authorization'] = 'Bearer $token';

      final fileName = imageFile.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          imageFile.path,
          filename: fileName,
        ),
      });

      AppLogger().info('Uploading image: $fileName');
      AppLogger().info('Upload URL: ${AppConfig.baseUrl}/upload/image');

      final response = await _dio.post(
        '/upload/image',
        data: formData,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'];
        final url = data['url'] as String;
        AppLogger().info('Image uploaded successfully: $url');
        return url;
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } on DioException catch (e) {
      AppLogger().error('Dio error uploading image: ${e.message}');
      AppLogger().error('Response: ${e.response?.data}');
      throw Exception('Network error uploading image: ${e.message}');
    } catch (e) {
      AppLogger().error('Error uploading image: $e');
      rethrow;
    }
  }

  /// Upload multiple image files
  ///
  /// Returns a list of URLs of the uploaded images
  Future<List<String>> uploadImages(List<File> imageFiles) async {
    final urls = <String>[];

    for (final file in imageFiles) {
      try {
        final url = await uploadImage(file);
        urls.add(url);
      } catch (e) {
        AppLogger().error('Failed to upload image ${file.path}: $e');
        // Continue with other images
      }
    }

    return urls;
  }
}
