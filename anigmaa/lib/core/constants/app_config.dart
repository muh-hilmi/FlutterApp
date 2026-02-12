import 'dart:io';
import '../services/environment_service.dart';

/// Application configuration management
/// Handles environment-specific settings and URLs
class AppConfig {
  // API Configuration
  static const String apiBasePath = '/api/v1';

  /// Get the base URL for current environment
  static String get baseUrl {
    String url = EnvironmentService.apiBaseUrl;

    // Handle Android emulator localhost mapping
    // For local development with backend running in Docker WSL:
    // - Android emulator sees host Windows at 10.0.2.2
    // - Docker WSL forwards ports to host Windows
    // - So we need to replace localhost with 10.0.2.2 for Android
    if (EnvironmentService.isDevelopment && Platform.isAndroid) {
      // Check if it's a localhost URL (backend in Docker/WSL)
      if (url.contains('localhost') || url.contains('127.0.0.1')) {
        return url.replaceAll(RegExp(r'localhost|127\.0\.0\.1'), '10.0.2.2');
      }
    }

    return url;
  }

  /// Get the full API URL with version path
  static String get apiUrl => '$baseUrl$apiBasePath';

  /// Get API version
  static String get apiVersion => EnvironmentService.apiVersion;

  /// Current environment
  static String get environment => EnvironmentService.environment;

  /// Check if running in debug mode
  static bool get isDebugMode => !EnvironmentService.isProduction;

  /// Check if running in development mode
  static bool get isDevelopment => EnvironmentService.isDevelopment;

  /// API timeout configurations
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  /// Feature flags
  static bool get darkModeEnabled => EnvironmentService.darkModeEnabled;
  static bool get pushNotificationsEnabled => EnvironmentService.pushNotificationsEnabled;
  static bool get locationServicesEnabled => EnvironmentService.locationServicesEnabled;
  static bool get analyticsEnabled => EnvironmentService.analyticsEnabled;
}

/// Application environment enumeration
enum AppEnvironment {
  development,
  staging,
  production,
}
