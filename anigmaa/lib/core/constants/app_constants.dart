class AppConstants {
  static const String appName = 'Anigmaa';
  static const String appVersion = '1.0.0';
  
  // API Configuration
  static const String baseUrl = 'http://localhost:8123';
  static const String apiVersion = 'v1';
  static String apiBaseUrl = _getApiBaseUrl();
  
  // API Timeouts
  static const int connectTimeout = 30000; // 30 seconds
  static const int receiveTimeout = 30000; // 30 seconds
  static const int sendTimeout = 30000; // 30 seconds
  
  // URLs
  static const String websiteUrl = 'https://anigmaa.com';
  static const String supportEmail = 'support@anigmaa.com';
  static const String privacyPolicyUrl = '$websiteUrl/privacy';
  static const String termsOfServiceUrl = '$websiteUrl/terms';
  
  // Storage Keys
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userProfileKey = 'user_profile';
  static const String onboardingCompletedKey = 'onboarding_completed';
  static const String firstLaunchKey = 'first_launch';
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // File Upload
  static const int maxFileSizeBytes = 20 * 1024 * 1024; // 20MB
  static const List<String> supportedImageTypes = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> supportedDocumentTypes = ['pdf', 'doc', 'docx'];
  
  // Rate Limiting
  static const int maxLoginAttempts = 5;
  static const Duration loginCooldown = Duration(minutes: 15);
  
  // Cache Duration
  static const Duration defaultCacheDuration = Duration(minutes: 5);
  static const Duration longCacheDuration = Duration(hours: 24);
  static const Duration shortCacheDuration = Duration(minutes: 1);
  
  // Animation Durations
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);
  
  // UI Constraints
  static const double maxContentWidth = 1200.0;
  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  
  static String _getApiBaseUrl() {
    // In production, this would come from environment variables
    // For now, return development URL
    return 'http://localhost:8123';
  }
}
