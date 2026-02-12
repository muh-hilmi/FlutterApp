import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Centralized logging utility for the application.
/// Automatically disables verbose logging in production mode.
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  late final Logger _logger;

  /// Initialize the logger with appropriate settings
  void init({bool enableInRelease = false}) {
    // Only show logs in debug mode unless explicitly enabled
    final shouldLog = kDebugMode || enableInRelease;

    _logger = Logger(
      filter: shouldLog ? DevelopmentFilter() : ProductionFilter(),
      printer: SimplePrinter(
        colors: true,
        printTime: false,
      ),
      output: ConsoleOutput(),
    );
  }

  Logger get logger => _logger;

  // Convenience methods
  void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.d(message, error: error, stackTrace: stackTrace);
    }
  }

  void info(String message, [dynamic error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _logger.i(message, error: error, stackTrace: stackTrace);
    }
  }

  void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  void wtf(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }
}

/// Simplified logger for network requests
class NetworkLogger {
  static final AppLogger _appLogger = AppLogger();

  static void logRequest(String method, String path, {Map<String, dynamic>? queryParams, dynamic data}) {
    if (kDebugMode) {
      final query = queryParams != null && queryParams.isNotEmpty ? '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}' : '';
      final body = data != null ? '\n  Body: ${data.toString().length > 100 ? '${data.toString().substring(0, 100)}...' : data}' : '';
      _appLogger.debug('→ $method $path$query$body');
    }
  }

  static void logResponse(int? statusCode, String path, {Duration? duration, dynamic data}) {
    if (kDebugMode) {
      final durationStr = duration != null ? ' (${duration.inMilliseconds}ms)' : '';
      final responseData = data != null && kDebugMode
          ? '\n  Response: ${data.toString().length > 200 ? '${data.toString().substring(0, 200)}...' : data}'
          : '';

      if (statusCode != null && statusCode >= 200 && statusCode < 300) {
        _appLogger.info('← $statusCode $path$durationStr$responseData');
      } else {
        _appLogger.warning('← $statusCode $path$durationStr$responseData');
      }
    }
  }

  static void logError(int? statusCode, String path, String? message, {dynamic errorData}) {
    if (kDebugMode) {
      final errorDetails = errorData != null ? '\n  Error Data: $errorData' : '';
      _appLogger.error('✗ $statusCode $path${message != null ? ': $message' : ''}$errorDetails');
    }
  }
}
