import 'dart:async';
import 'package:dio/dio.dart';
import '../../core/api/dio_client.dart';
import '../../core/errors/failures.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponse> loginWithGoogle(String idToken);
  Future<void> logout();
  Future<UserModel> getCurrentUser();
  Future<UserModel> updateProfile(Map<String, dynamic> profileData);
  Future<AuthResponse> refreshToken(String refreshToken);
}

class AuthResponse {
  final UserModel user;
  final String accessToken;
  final String refreshToken;

  AuthResponse({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Support both camelCase and snake_case from backend
    final accessToken = json['accessToken'] ?? json['access_token'];
    final refreshToken = json['refreshToken'] ?? json['refresh_token'];

    // Validate required fields
    if (json['user'] == null) {
      throw Exception('Missing user data in auth response');
    }
    if (accessToken == null || (accessToken as String).isEmpty) {
      throw Exception('Missing accessToken in auth response');
    }
    if (refreshToken == null || (refreshToken as String).isEmpty) {
      throw Exception('Missing refreshToken in auth response');
    }

    return AuthResponse(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final DioClient dioClient;

  AuthRemoteDataSourceImpl({required this.dioClient});

  @override
  Future<AuthResponse> loginWithGoogle(String idToken) async {
    try {
      // Wrap with explicit timeout to prevent infinite loading when retry queue traps the request
      // This ensures we get an exception even if the RetryInterceptor queues the request
      // 10s timeout = 1 retry (1s) + connection timeout + buffer
      final response = await dioClient.post(
        '/auth/google',
        data: {
          'idToken': idToken,
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Login request timeout - server unreachable');
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] ?? response.data;

        try {
          return AuthResponse.fromJson(data);
        } catch (e) {
          throw ServerFailure('Invalid response format from server: $e');
        }
      } else {
        throw ServerFailure('Failed to authenticate with Google');
      }
    } on TimeoutException catch (_) {
      // Explicit timeout from .timeout() wrapper - backend is unreachable after all retries
      // This is different from Dio's timeout - it means the retry queue also timed out
      throw NetworkFailure('Server lagi sibuk atau mati 😴\n\n'
          'Coba:\n'
          '• Cek koneksi internet\n'
          '• Tunggu bentar, coba lagi');
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> logout() async {
    try {
      final response = await dioClient.post('/auth/logout');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw ServerFailure('Failed to logout');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await dioClient.get('/users/me');

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        // Handle both {data: {user: {...}}} and {data: {id: ..., name: ...}}
        final userData = data['user'] ?? data;
        return UserModel.fromJson(userData);
      } else {
        throw ServerFailure('Failed to get current user');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<UserModel> updateProfile(Map<String, dynamic> profileData) async {
    try {
      final response = await dioClient.put(
        '/users/me',
        data: profileData,
      );

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        // Handle both {data: {user: {...}}} and {data: {id: ..., name: ...}}
        final userData = data['user'] ?? data;
        return UserModel.fromJson(userData);
      } else {
        throw ServerFailure('Failed to update profile');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final response = await dioClient.post(
        '/auth/refresh',
        data: {
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] ?? response.data;

        try {
          return AuthResponse.fromJson(data);
        } catch (e) {
          throw ServerFailure('Invalid refresh response format from server: $e');
        }
      } else {
        throw ServerFailure('Failed to refresh token');
      }
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  Failure _handleDioException(DioException e) {
    final errorMsg = e.message?.toLowerCase() ?? '';
    final errorStr = e.error?.toString().toLowerCase() ?? '';

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return _classifyTimeoutError(errorMsg, errorStr);

      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data['message'] ?? 'Server error';
        if (statusCode == 401) {
          return AuthenticationFailure(message);
        } else if (statusCode == 403) {
          return AuthorizationFailure(message);
        } else if (statusCode == 404) {
          return NotFoundFailure(message);
        } else {
          return ServerFailure(message);
        }

      case DioExceptionType.cancel:
        return NetworkFailure('Request dibatalkan');

      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return _classifyConnectionError(errorMsg, errorStr, e);

      case DioExceptionType.badCertificate:
        return NetworkFailure('SSL-nya bermasalah 🔒\n\n'
            'Cek jam/tanggal di HP lo.');

      default:
        return ServerFailure('Error bingung 🤔\n\nCoba lagi ya.');
    }
  }

  /// Classify timeout errors more specifically
  Failure _classifyTimeoutError(String errorMsg, String errorStr) {
    if (errorMsg.contains('connection') || errorMsg.contains('connect')) {
      return NetworkFailure('Server gabisa dihubungi 😵‍💫\n\n'
          'Coba:\n'
          '• Cek internet lo\n'
          '• Tunggu bentar, coba lagi');
    }
    if (errorMsg.contains('receive') || errorMsg.contains('response')) {
      return NetworkFailure('Server lagi lemot banget 🐌\n\n'
          'Sabar ya, coba lagi bentar.');
    }
    return NetworkFailure('Waktunya habis 🕐\n\nCoba lagi deh.');
  }

  /// Classify connection errors to identify specific issues
  Failure _classifyConnectionError(String errorMsg, String errorStr, DioException e) {
    // Connection refused = backend not running OR wrong port
    if (errorMsg.contains('connection refused') ||
        errorMsg.contains('errno') ||
        errorStr.contains('connection refused')) {
      return NetworkFailure('Server lagi mati 🔴\n\n'
          'Backend-nya belum dinyalain.\n'
          'Hubungi admin buat nyalain server.');
    }

    // Failed host lookup = DNS issue (no internet OR wrong URL)
    if (errorMsg.contains('failed host lookup') ||
        errorMsg.contains('nodename') ||
        errorMsg.contains('servname')) {
      return NetworkFailure('Ilang koneksi 📡\n\n'
          'Wifi / data lo mati. Cek dulu deh.');
    }

    // Network unreachable = no internet at all
    if (errorMsg.contains('network is unreachable') ||
        errorMsg.contains('no internet') ||
        errorMsg.contains('offline')) {
      return NetworkFailure('Ga ada internet 📵\n\n'
          'Nyalain wifi / data dulu ya.');
    }

    // Socket error = various network issues
    if (errorMsg.contains('socket') || errorMsg.contains('broken pipe')) {
      return NetworkFailure('Koneksi putus 🔌\n\n'
          'Wifi ilang kali. Cek lagi deh.');
    }

    // Default connection error
    return NetworkFailure('Server gabisa dihubungi 😢\n\n'
        'Cek internet lo ya.');
  }
}
