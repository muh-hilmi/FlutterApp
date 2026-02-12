import 'package:dio/dio.dart';
import '../constants/app_config.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';
import '../network/error_classifier.dart';
import '../network/retry_interceptor.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/logging_interceptor.dart';

/// HTTP client wrapper using Dio for API communications
/// Provides a centralized network layer with proper error handling and logging
///
/// Features:
/// - Automatic retry with exponential backoff for transient failures
/// - Proper error classification (network vs auth vs server errors)
/// - Connection timeout handling
/// - Request/response logging
/// - Token refresh notification to AuthBloc
class DioClient {
  late final Dio _dio;
  final AppLogger _logger = AppLogger();

  /// Retry interceptor instance for access to retry functionality
  late final RetryInterceptor _retryInterceptor;

  /// Auth interceptor instance for setting callbacks
  late final AuthInterceptor _authInterceptor;

  DioClient() {
    _dio = _createDioInstance();
    _retryInterceptor = RetryInterceptor(dio: _dio);
    _addInterceptors();
  }

  /// Creates and configures Dio instance
  Dio _createDioInstance() {
    return Dio(
      BaseOptions(
        baseUrl: AppConfig.apiUrl,
        connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
        receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
        sendTimeout: const Duration(milliseconds: AppConstants.sendTimeout),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        // 2xx and 409 are considered successful responses
        // - 2xx: Standard success responses
        // - 409: Conflict (e.g., post already liked) - edge case that needs handling in datasource
        // Other 4xx errors (401, 403, 404, etc.) will throw exceptions for proper handling
        validateStatus: (status) => status != null &&
            ((status >= 200 && status < 300) || status == 409),
      ),
    );
  }

  /// Adds interceptors to Dio instance
  ///
  /// Order matters:
  /// 1. RetryInterceptor - handles retries first
  /// 2. AuthInterceptor - handles auth tokens
  /// 3. LoggingInterceptor - logs all requests/responses
  void _addInterceptors() {
    _authInterceptor = AuthInterceptor();
    _dio.interceptors.addAll([
      _retryInterceptor,
      _authInterceptor,
      LoggingInterceptor(),
    ]);
  }

  /// Set callback to be called when token is successfully refreshed
  ///
  /// This should be called after dependency injection is complete,
  /// typically from AuthBloc's constructor or initialization
  void setOnTokenRefreshedCallback(OnTokenRefreshedCallback callback) {
    _authInterceptor.onTokenRefreshed = callback;
    _logger.debug('[DioClient] Token refresh callback registered');
  }

  /// Get the retry interceptor instance
  RetryInterceptor get retryInterceptor => _retryInterceptor;

  /// Get the underlying Dio instance for advanced usage
  Dio get dio => _dio;

  /// Performs HTTP GET request
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      _logger.debug('GET request to $path');
      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      _handleError(e, 'GET', path);
      rethrow;
    }
  }

  /// Performs HTTP POST request
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      _logger.debug('POST request to $path');
      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      _handleError(e, 'POST', path);
      rethrow;
    }
  }

  /// Performs HTTP PUT request
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      _logger.debug('PUT request to $path');
      return await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      _handleError(e, 'PUT', path);
      rethrow;
    }
  }

  /// Performs HTTP DELETE request
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      _logger.debug('DELETE request to $path');
      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
    } catch (e) {
      _handleError(e, 'DELETE', path);
      rethrow;
    }
  }

  /// Performs HTTP PATCH request
  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      _logger.debug('PATCH request to $path');
      return await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
    } catch (e) {
      _handleError(e, 'PATCH', path);
      rethrow;
    }
  }

  /// Downloads file from URL
  Future<Response> download(
    String urlPath,
    String savePath, {
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
    bool deleteOnError = true,
    String lengthHeader = Headers.contentLengthHeader,
    dynamic data,
    Options? options,
  }) async {
    try {
      _logger.debug('Downloading file from $urlPath');
      return await _dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        deleteOnError: deleteOnError,
        lengthHeader: lengthHeader,
        data: data,
        options: options,
      );
    } catch (e) {
      _handleError(e, 'DOWNLOAD', urlPath);
      rethrow;
    }
  }

  /// Centralized error handling with proper error classification
  void _handleError(dynamic error, String method, String path) {
    // Classify the error for better logging and potential user feedback
    final networkError = ErrorClassifier.classify(error);

    _logger.error(
      '$method request failed for $path - Type: ${networkError.type}, '
      'Retryable: ${networkError.isRetryable}',
      error,
    );

    // The actual error is rethrown, so callers can handle it
    // The classification above is primarily for logging
  }
}
