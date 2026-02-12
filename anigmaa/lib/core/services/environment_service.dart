import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../constants/app_constants.dart';

/// Service for managing environment variables and app configuration
/// Provides secure access to environment-specific settings
class EnvironmentService {
  static bool _initialized = false;

  /// Initialize environment variables from .env file
  static Future<void> initialize() async {
    if (!_initialized) {
      try {
        await dotenv.load(fileName: '.env');
        _initialized = true;
      } catch (e) {
        // Use default values if .env file is not found
        _initialized = true;
      }
    }
  }

  // Environment Configuration
  static String get environment => dotenv.env['APP_ENV'] ?? 'development';
  static bool get isDevelopment => environment == 'development';
  static bool get isStaging => environment == 'staging';
  static bool get isProduction => environment == 'production';

  // API Configuration
  static String get apiBaseUrl {
    final envUrl = dotenv.env['API_BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    // Fallback to AppConstants
    return AppConstants.baseUrl;
  }

  static String get apiVersion => dotenv.env['API_VERSION'] ?? AppConstants.apiVersion;

  // Feature Flags
  static bool get darkModeEnabled => dotenv.env['ENABLE_DARK_MODE'] == 'true';
  static bool get pushNotificationsEnabled => dotenv.env['ENABLE_PUSHLNOTIFICATIONS'] == 'true';
  static bool get locationServicesEnabled => dotenv.env['ENABLE_LOCATION_SERVICES'] == 'true';
  static bool get analyticsEnabled => dotenv.env['ENABLE_ANALYTICS'] == 'true';

  // Security Keys (Production only)
  static String? get encryptionKey => isProduction ? dotenv.env['ENCRYPTION_KEY'] : null;
  static String? get jwtSecret => isProduction ? dotenv.env['JWT_SECRET'] : null;

  // External Services
  static String? get sentryDsn => dotenv.env['SENTRY_DSN'];
  static String? get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'];

  /// Validate required environment variables
  static bool validateEnvironment() {
    if (isProduction) {
      // In production, certain variables are required
      final requiredVars = ['ENCRYPTION_KEY', 'JWT_SECRET'];
      for (final varName in requiredVars) {
        if (dotenv.env[varName]?.isEmpty ?? true) {
          return false;
        }
      }
    }
    return true;
  }
}