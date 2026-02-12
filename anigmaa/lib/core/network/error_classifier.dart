import 'package:dio/dio.dart';
import '../errors/failures.dart';

/// Classification of network error types
enum ErrorType {
  /// Network connectivity issue (connection refused, no internet)
  network,

  /// Request timeout (connect, send, receive)
  timeout,

  /// Authentication error (401) - may need token refresh
  auth,

  /// Server error (5xx) - temporary server issue
  server,

  /// Client error (4xx except 401) - bad request, not retryable
  client,

  /// Unknown error type
  unknown,
}

/// Action to take for error recovery
enum RecoveryAction {
  /// Retry the request with exponential backoff
  retryWithBackoff,

  /// Try to refresh the access token
  refreshToken,

  /// Log the user out (auth completely failed)
  logout,

  /// Show error message to user
  showError,

  /// Ignore the error silently
  ignore,
}

/// Represents a classified network error with recovery information
class NetworkError {
  final ErrorType type;
  final RecoveryAction action;
  final String message;
  final int? statusCode;
  final bool isRetryable;
  final DioException? originalException;

  const NetworkError({
    required this.type,
    required this.action,
    required this.message,
    this.statusCode,
    required this.isRetryable,
    this.originalException,
  });

  /// Convert to Failure for use with Either pattern
  Failure toFailure() {
    switch (type) {
      case ErrorType.network:
        return NetworkFailure(message);
      case ErrorType.timeout:
        return TimeoutFailure(message);
      case ErrorType.auth:
        return AuthenticationFailure(message);
      case ErrorType.server:
        return ServerFailure(message);
      case ErrorType.client:
        return ClientFailure(message);
      case ErrorType.unknown:
        return UnknownFailure(message);
    }
  }

  @override
  String toString() {
    return 'NetworkError(type: $type, action: $action, message: $message, '
        'statusCode: $statusCode, isRetryable: $isRetryable)';
  }
}

/// Classifier for network errors
///
/// Determines the type of error and appropriate recovery action.
/// Critical for distinguishing between transient failures (retryable)
/// and permanent failures (not retryable).
class ErrorClassifier {
  /// Classify a generic error into a NetworkError
  static NetworkError classify(dynamic error) {
    if (error is NetworkError) {
      return error;
    }

    if (error is! DioException) {
      return NetworkError(
        type: ErrorType.unknown,
        action: RecoveryAction.showError,
        message: 'Unknown error occurred',
        isRetryable: false,
        originalException: null,
      );
    }

    final dioError = error;

    switch (dioError.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.cancel:
        return NetworkError(
          type: ErrorType.timeout,
          action: RecoveryAction.retryWithBackoff,
          message: 'Connection timeout. Check your internet connection.',
          isRetryable: true,
          originalException: dioError,
        );

      case DioExceptionType.sendTimeout:
        return NetworkError(
          type: ErrorType.timeout,
          action: RecoveryAction.retryWithBackoff,
          message: 'Send timeout. Please try again.',
          isRetryable: true,
          originalException: dioError,
        );

      case DioExceptionType.receiveTimeout:
        return NetworkError(
          type: ErrorType.timeout,
          action: RecoveryAction.retryWithBackoff,
          message: 'Server took too long to respond. Please try again.',
          isRetryable: true,
          originalException: dioError,
        );

      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        // Check error message to distinguish connection refused from other unknown errors
        final errorMsg = dioError.message?.toLowerCase() ?? '';

        if (errorMsg.contains('connection refused') ||
            errorMsg.contains('failed host lookup') ||
            errorMsg.contains('network is unreachable') ||
            errorMsg.contains('internet')) {
          return NetworkError(
            type: ErrorType.network,
            action: RecoveryAction.retryWithBackoff,
            message: 'Cannot reach server. Please check your connection.',
            isRetryable: true,
            originalException: dioError,
          );
        }

        // Default unknown error
        return NetworkError(
          type: ErrorType.unknown,
          action: RecoveryAction.showError,
          message: dioError.message ?? 'An unknown error occurred',
          isRetryable: false,
          originalException: dioError,
        );

      case DioExceptionType.badResponse:
        final status = dioError.response?.statusCode;

        if (status == 401) {
          return NetworkError(
            type: ErrorType.auth,
            action: RecoveryAction.refreshToken,
            message: 'Session expired',
            statusCode: 401,
            isRetryable: true,
            originalException: dioError,
          );
        } else if (status == 403) {
          return NetworkError(
            type: ErrorType.auth,
            action: RecoveryAction.logout,
            message: 'Access denied',
            statusCode: 403,
            isRetryable: false,
            originalException: dioError,
          );
        } else if (status != null && status >= 500 && status < 600) {
          return NetworkError(
            type: ErrorType.server,
            action: RecoveryAction.retryWithBackoff,
            message: 'Server error. Please try again.',
            statusCode: status,
            isRetryable: true,
            originalException: dioError,
          );
        } else if (status != null && status >= 400 && status < 500) {
          return NetworkError(
            type: ErrorType.client,
            action: RecoveryAction.showError,
            message: 'Request error: ${_getClientErrorMessage(status)}',
            statusCode: status,
            isRetryable: false,
            originalException: dioError,
          );
        }
        break;

      case DioExceptionType.badCertificate:
        return NetworkError(
          type: ErrorType.client,
          action: RecoveryAction.showError,
          message: 'Invalid SSL certificate',
          isRetryable: false,
          originalException: dioError,
        );
    }

    return NetworkError(
      type: ErrorType.unknown,
      action: RecoveryAction.showError,
      message: dioError.message ?? 'Unknown error',
      isRetryable: false,
      originalException: dioError,
    );
  }

  /// Get user-friendly message for client errors
  static String _getClientErrorMessage(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 404:
        return 'Requested resource not found.';
      case 409:
        return 'Resource conflict. It may already exist.';
      case 422:
        return 'Validation error. Please check your input.';
      case 429:
        return 'Too many requests. Please wait.';
      default:
        return 'Client error ($statusCode)';
    }
  }

  /// Check if error is a network connectivity issue (not auth, not server bug)
  static bool isNetworkError(dynamic error) {
    final classified = classify(error);
    return classified.type == ErrorType.network ||
           classified.type == ErrorType.timeout;
  }

  /// Check if error is an auth issue (may need token refresh)
  static bool isAuthError(dynamic error) {
    final classified = classify(error);
    return classified.type == ErrorType.auth;
  }

  /// Check if error is retryable (transient)
  static bool isRetryable(dynamic error) {
    final classified = classify(error);
    return classified.isRetryable;
  }
}
