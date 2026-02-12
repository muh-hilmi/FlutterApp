import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  factory ApiException.fromDioException(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return ApiException(
          message: 'Connection timeout. Please check your internet connection.',
          statusCode: 408,
        );
      case DioExceptionType.sendTimeout:
        return ApiException(
          message: 'Send timeout. Please try again.',
          statusCode: 408,
        );
      case DioExceptionType.receiveTimeout:
        return ApiException(
          message: 'Receive timeout. Please try again.',
          statusCode: 408,
        );
      case DioExceptionType.badResponse:
        return _handleBadResponse(error.response);
      case DioExceptionType.cancel:
        return ApiException(
          message: 'Request cancelled',
        );
      case DioExceptionType.connectionError:
        return ApiException(
          message: 'No internet connection. Please check your network.',
        );
      case DioExceptionType.badCertificate:
        return ApiException(
          message: 'Certificate verification failed',
        );
      case DioExceptionType.unknown:
      return ApiException(
          message: error.message ?? 'Unknown error occurred',
        );
    }
  }

  static ApiException _handleBadResponse(Response? response) {
    if (response == null) {
      return ApiException(
        message: 'Unknown error occurred',
      );
    }

    final statusCode = response.statusCode ?? 0;
    final data = response.data;

    // Try to extract error message from response
    String message = 'An error occurred';

    if (data is Map<String, dynamic>) {
      message = data['error'] ??
                data['message'] ??
                data['detail'] ??
                'An error occurred';
    } else if (data is String) {
      message = data;
    }

    switch (statusCode) {
      case 400:
        return ApiException(
          message: message.isNotEmpty ? message : 'Bad request',
          statusCode: statusCode,
          data: data,
        );
      case 401:
        return ApiException(
          message: message.isNotEmpty ? message : 'Unauthorized. Please login again.',
          statusCode: statusCode,
          data: data,
        );
      case 403:
        return ApiException(
          message: message.isNotEmpty ? message : 'Access forbidden',
          statusCode: statusCode,
          data: data,
        );
      case 404:
        return ApiException(
          message: message.isNotEmpty ? message : 'Resource not found',
          statusCode: statusCode,
          data: data,
        );
      case 409:
        return ApiException(
          message: message.isNotEmpty ? message : 'Conflict occurred',
          statusCode: statusCode,
          data: data,
        );
      case 422:
        return ApiException(
          message: message.isNotEmpty ? message : 'Validation error',
          statusCode: statusCode,
          data: data,
        );
      case 429:
        return ApiException(
          message: message.isNotEmpty ? message : 'Too many requests. Please try again later.',
          statusCode: statusCode,
          data: data,
        );
      case 500:
        return ApiException(
          message: message.isNotEmpty ? message : 'Internal server error',
          statusCode: statusCode,
          data: data,
        );
      case 502:
        return ApiException(
          message: message.isNotEmpty ? message : 'Bad gateway',
          statusCode: statusCode,
          data: data,
        );
      case 503:
        return ApiException(
          message: message.isNotEmpty ? message : 'Service unavailable',
          statusCode: statusCode,
          data: data,
        );
      default:
        return ApiException(
          message: message,
          statusCode: statusCode,
          data: data,
        );
    }
  }

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode)';
  }
}
