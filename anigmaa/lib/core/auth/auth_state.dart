/// Complete authentication state machine
///
/// States and their meaning:
/// - INITIAL: App just launched, no checks performed yet
/// - VALIDATING: Checking stored token against API
/// - VALIDATED: Token confirmed valid via API
/// - REFRESHING: Attempting to refresh expired access token
/// - UNAUTHENTICATED: No valid token, user must login
/// - SERVER_UNAVAILABLE: Network error, token may be valid
/// - OFFLINE_MODE: Server unavailable but allowing offline access
/// - ERROR: Non-recoverable error during auth flow
enum AuthState {
  /// Initial state, no checks performed
  initial,

  /// Currently validating token with API
  validating,

  /// Token validated successfully
  validated,

  /// Attempting to refresh token
  refreshing,

  /// No valid token exists or refresh failed
  unauthenticated,

  /// Server unreachable (network error)
  serverUnavailable,

  /// Server unavailable but allowing limited offline access
  offlineMode,

  /// Non-recoverable error occurred
  error,
}

/// Extension for AuthState helper methods
extension AuthStateX on AuthState {
  /// Whether user is considered authenticated (can access protected features)
  bool get isAuthenticated =>
      this == AuthState.validated || this == AuthState.offlineMode;

  /// Whether we should show a loading indicator
  bool get isLoading =>
      this == AuthState.validating || this == AuthState.refreshing;

  /// Whether we can allow offline access to cached content
  bool get canUseOfflineMode =>
      this == AuthState.serverUnavailable || this == AuthState.offlineMode;

  /// Whether we should redirect to login
  bool get shouldShowLogin => this == AuthState.unauthenticated;

  /// Whether we should block the user from proceeding
  bool get isBlocking =>
      this == AuthState.validating ||
      this == AuthState.refreshing ||
      this == AuthState.error;

  /// User-friendly description
  String get description {
    switch (this) {
      case AuthState.initial:
        return 'Initializing...';
      case AuthState.validating:
        return 'Verifying session...';
      case AuthState.validated:
        return 'Authenticated';
      case AuthState.refreshing:
        return 'Refreshing session...';
      case AuthState.unauthenticated:
        return 'Please login to continue';
      case AuthState.serverUnavailable:
        return 'Server unreachable. Check your connection.';
      case AuthState.offlineMode:
        return 'Offline mode - limited features available';
      case AuthState.error:
        return 'An error occurred. Please try again.';
    }
  }
}

/// Result of a token validation attempt
enum TokenValidationResult {
  /// Token is valid
  valid,

  /// Token is invalid or expired
  invalid,

  /// Network error, couldn't validate
  networkError,

  /// Server error (5xx)
  serverError,
}

/// Data class for auth state with additional context
class AuthStateData {
  final AuthState state;
  final String? errorMessage;
  final DateTime? validatedAt;
  final int retryCount;

  const AuthStateData({
    required this.state,
    this.errorMessage,
    this.validatedAt,
    this.retryCount = 0,
  });

  /// Initial state
  static const initial = AuthStateData(state: AuthState.initial);

  /// Copy with
  AuthStateData copyWith({
    AuthState? state,
    String? errorMessage,
    DateTime? validatedAt,
    int? retryCount,
    bool clearErrorMessage = false,
  }) {
    return AuthStateData(
      state: state ?? this.state,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      validatedAt: validatedAt ?? this.validatedAt,
      retryCount: retryCount ?? this.retryCount,
    );
  }

  /// Whether the token was validated recently (within 5 minutes)
  bool get isRecentlyValidated {
    if (validatedAt == null) return false;
    final now = DateTime.now();
    final difference = now.difference(validatedAt!);
    return difference.inMinutes < 5;
  }
}
