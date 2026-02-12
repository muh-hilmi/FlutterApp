import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';
import '../../data/models/scan_result_model.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _initialize();
  }

  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  void _initialize() {
    _dio.options.baseUrl = AppConstants.apiBaseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    
    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          // Handle 401 unauthorized
          if (error.response?.statusCode == 401) {
            await _secureStorage.delete(key: 'auth_token');
            // You might want to navigate to login screen here
          }
          handler.next(error);
        },
      ),
    );
  }

  // User-related API calls
  Future<void> sendConnectionRequest(String userId) async {
    try {
      await _dio.post('/api/v1/users/connections', data: {
        'user_id': userId,
      });
    } catch (e) {
      AppLogger().error('Failed to send connection request: $e');
      rethrow;
    }
  }

  Future<List<ScanResultModel>> getEventMatches(String eventId) async {
    try {
      final response = await _dio.get('/api/v1/events/$eventId/matches');
      final data = response.data as List;
      return data.map((item) => ScanResultModel.fromJson(item)).toList();
    } catch (e) {
      AppLogger().error('Failed to get event matches: $e');
      // Return empty list instead of throwing
      return [];
    }
  }

  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    try {
      final response = await _dio.get('/api/v1/users/$userId');
      return response.data;
    } catch (e) {
      AppLogger().error('Failed to get user profile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getEventDetails(String eventId) async {
    try {
      final response = await _dio.get('/api/v1/events/$eventId');
      return response.data;
    } catch (e) {
      AppLogger().error('Failed to get event details: $e');
      rethrow;
    }
  }

  Future<void> updateUserProfile(Map<String, dynamic> userData) async {
    try {
      await _dio.put('/api/v1/users/profile', data: userData);
    } catch (e) {
      AppLogger().error('Failed to update user profile: $e');
      rethrow;
    }
  }

  Future<void> uploadProfileImage(String imagePath) async {
    try {
      final fileName = imagePath.split('/').last;
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(imagePath, filename: fileName),
      });
      
      await _dio.post('/api/v1/users/upload-avatar', data: formData);
    } catch (e) {
      AppLogger().error('Failed to upload profile image: $e');
      rethrow;
    }
  }

  // Generic GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      AppLogger().error('GET request failed for $path: $e');
      rethrow;
    }
  }

  // Generic POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      AppLogger().error('POST request failed for $path: $e');
      rethrow;
    }
  }

  // Generic PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      AppLogger().error('PUT request failed for $path: $e');
      rethrow;
    }
  }

  // Generic DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } catch (e) {
      AppLogger().error('DELETE request failed for $path: $e');
      rethrow;
    }
  }
}
