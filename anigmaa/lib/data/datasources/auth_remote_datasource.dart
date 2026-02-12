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
      final response = await dioClient.post(
        '/auth/google',
        data: {
          'idToken': idToken,
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
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return NetworkFailure('Connection timeout');
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
        return NetworkFailure('Request cancelled');
      case DioExceptionType.connectionError:
        return NetworkFailure('No internet connection');
      default:
        return ServerFailure('Unexpected error occurred');
    }
  }
}
