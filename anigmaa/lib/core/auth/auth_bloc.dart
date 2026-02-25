import 'dart:async';
import 'package:bloc/bloc.dart';
import '../services/auth_service.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../utils/app_logger.dart';
import '../api/dio_client.dart';
import '../errors/error_messages.dart';
import 'auth_state.dart';

/// Callback for token refresh notification
typedef OnTokenRefreshedCallback = void Function(String accessToken, String? refreshToken);

/// Events for AuthBloc
abstract class AuthEvent {}

class AuthValidateRequested extends AuthEvent {
  final bool forceRetry;
  AuthValidateRequested({this.forceRetry = false});
}

class AuthTokenRefreshed extends AuthEvent {
  final String accessToken;
  final String? refreshToken;
  AuthTokenRefreshed({required this.accessToken, this.refreshToken});
}

class AuthLogoutRequested extends AuthEvent {}

class AuthServerUnavailable extends AuthEvent {
  final bool allowOfflineMode;
  AuthServerUnavailable({this.allowOfflineMode = true});
}

class AuthRetryValidation extends AuthEvent {}

class AuthEnterOfflineMode extends AuthEvent {}

/// Bloc for managing authentication state
///
/// This bloc handles:
/// - Initial token validation on app start
/// - Token refresh coordination
/// - Network error handling
/// - Offline mode management
/// - Logout flow
class AuthBloc extends Bloc<AuthEvent, AuthStateData> {
  final AuthService _authService;
  final AuthRemoteDataSource _authDataSource;
  final DioClient? _dioClient; // Optional to avoid breaking changes
  final AppLogger _logger = AppLogger();

  // Request deduplication - prevent multiple simultaneous validations
  bool _isValidating = false;
  Completer<bool>? _validationCompleter;

  // Timer for periodic re-validation when in server unavailable state
  Timer? _retryTimer;

  // Stream controller for validation requests (queue system)
  final StreamController<AuthValidateRequested> _validationRequestController =
      StreamController<AuthValidateRequested>.broadcast();

  AuthBloc(
    this._authService,
    this._authDataSource, [
    this._dioClient,
  ]) : super(AuthStateData.initial) {
    // Register event handlers
    on<AuthValidateRequested>(_onValidateRequested);
    on<AuthTokenRefreshed>(_onTokenRefreshed);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthServerUnavailable>(_onServerUnavailable);
    on<AuthRetryValidation>(_onRetryValidation);
    on<AuthEnterOfflineMode>(_onEnterOfflineMode);

    // Listen to validation request stream (for queuing)
    _validationRequestController.stream.listen((request) {
      add(AuthValidateRequested(forceRetry: request.forceRetry));
    });

    // Register token refresh callback with DioClient if provided
    // This allows AuthInterceptor to notify AuthBloc when token is refreshed
    if (_dioClient != null) {
      _registerTokenRefreshCallback();
    } else {
      _logger.warning('[AuthBloc] DioClient not provided, token refresh callback not registered');
    }
  }

  /// Register callbacks to be notified by AuthInterceptor
  void _registerTokenRefreshCallback() {
    if (_dioClient == null) {
      _logger.warning('[AuthBloc] Cannot register callback: DioClient is null');
      return;
    }

    try {
      _dioClient!.setOnTokenRefreshedCallback((accessToken, refreshToken) {
        _logger.info('[AuthBloc] Token refresh callback received from AuthInterceptor');
        add(AuthTokenRefreshed(
          accessToken: accessToken,
          refreshToken: refreshToken,
        ));
      });

      _dioClient!.setOnSessionExpiredCallback(() {
        _logger.warning('[AuthBloc] Session expired callback received — logging out');
        add(AuthLogoutRequested());
      });

      _logger.debug('[AuthBloc] Auth callbacks registered successfully');
    } catch (e) {
      _logger.error('[AuthBloc] Failed to register token refresh callback', e);
    }
  }

  @override
  Future<void> close() {
    _retryTimer?.cancel();
    _validationRequestController.close();
    return super.close();
  }

  /// Validate stored token against API
  ///
  /// Returns true if validation is currently in progress (callers can wait)
  bool validateToken({bool forceRetry = false}) {
    // If already validating, return true to indicate in progress
    if (_isValidating && !forceRetry) {
      _logger.debug('[AuthBloc] Validation already in progress, skipping');
      return true;
    }

    // Add validation request to stream
    _validationRequestController.add(AuthValidateRequested(forceRetry: forceRetry));
    return _isValidating;
  }

  /// Wait for current validation to complete
  Future<bool> waitForValidation() async {
    if (_isValidating && _validationCompleter != null) {
      return _validationCompleter!.future;
    }
    return true; // No validation in progress
  }

  /// Get current auth state
  AuthState get currentAuthState => state.state;

  /// Check if user is authenticated
  bool get isAuthenticated => state.state.isAuthenticated;

  /// Check if token was recently validated (within 5 minutes)
  bool get isRecentlyValidated => state.isRecentlyValidated;

  Future<void> _onValidateRequested(
    AuthValidateRequested event,
    Emitter<AuthStateData> emit,
  ) async {
    // Skip if already validating (unless force retry)
    if (_isValidating && !event.forceRetry) {
      _logger.debug('[AuthBloc] Validation already in progress');
      return;
    }

    // Check if we have a token at all
    final hasToken = await _authService.hasValidToken;
    if (!hasToken) {
      _logger.info('[AuthBloc] No token found, user is unauthenticated');
      emit(AuthStateData(state: AuthState.unauthenticated));
      return;
    }

    // Check if recently validated (skip validation to save API calls)
    if (state.isRecentlyValidated && !event.forceRetry) {
      _logger.info('[AuthBloc] Token recently validated, skipping');
      emit(state.copyWith(state: AuthState.validated));
      return;
    }

    // Start validation
    _isValidating = true;
    _validationCompleter = Completer<bool>();
    emit(state.copyWith(state: AuthState.validating));

    _logger.info('[AuthBloc] Validating token...');

    try {
      // Call API to validate token (with timeout)
      // Reduced timeout for faster user feedback (5s instead of 10s)
      final user = await _authDataSource.getCurrentUser().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Token validation timeout');
        },
      );

      // Success - token is valid
      _logger.info('[AuthBloc] Token validated for user: ${user.email}');
      _isValidating = false;
      _retryTimer?.cancel();
      _validationCompleter?.complete(true);

      emit(AuthStateData(
        state: AuthState.validated,
        validatedAt: DateTime.now(),
        retryCount: 0,
      ));
    } catch (e, stackTrace) {
      _logger.error('[AuthBloc] Token validation failed', e, stackTrace);
      _isValidating = false;

      // Classify the error
      final result = _classifyValidationException(e);

      switch (result) {
        case TokenValidationResult.invalid:
          // Token is invalid - clear it and go to login
          _logger.warning('[AuthBloc] Token invalid, clearing auth data');
          await _authService.clearAuthData();
          _retryTimer?.cancel();
          _validationCompleter?.complete(false);
          emit(AuthStateData(
            state: AuthState.unauthenticated,
            errorMessage: ErrorMessageResolver.sessionExpired,
            retryCount: 0,
          ));
          break;

        case TokenValidationResult.networkError:
          // Network error - don't clear token
          _logger.warning('[AuthBloc] Network error during validation');
          _validationCompleter?.complete(false);

          final newRetryCount = state.retryCount + 1;
          if (newRetryCount >= 3) {
            // Too many retries, show clearer message
            emit(state.copyWith(
              state: AuthState.serverUnavailable,
              errorMessage: ErrorMessageResolver.genericNetworkError,
              retryCount: newRetryCount,
            ));
            _startRetryTimer();
          } else {
            // Retry automatically with loading message
            emit(state.copyWith(
              state: AuthState.serverUnavailable,
              errorMessage: 'Tidak dapat terhubung ke server. Mencoba ulang...',
              retryCount: newRetryCount,
            ));
            _startRetryTimer();
          }
          break;

        case TokenValidationResult.serverError:
          // Server error (5xx) - don't clear token, might be temporary
          _logger.warning('[AuthBloc] Server error during validation');
          _validationCompleter?.complete(false);

          emit(state.copyWith(
            state: AuthState.serverUnavailable,
            errorMessage: ErrorMessageResolver.internalServerError,
            retryCount: state.retryCount + 1,
          ));
          _startRetryTimer();
          break;

        case TokenValidationResult.valid:
          // Shouldn't reach here, but handle gracefully
          _isValidating = false;
          _validationCompleter?.complete(true);
          emit(AuthStateData(
            state: AuthState.validated,
            validatedAt: DateTime.now(),
          ));
          break;
      }
    }
  }

  Future<void> _onTokenRefreshed(
    AuthTokenRefreshed event,
    Emitter<AuthStateData> emit,
  ) async {
    _logger.info('[AuthBloc] Token refreshed successfully');

    // Store new tokens
    if (event.refreshToken != null) {
      await _authService.updateTokens(
        accessToken: event.accessToken,
        refreshToken: event.refreshToken!,
      );
    } else {
      // Only update access token, keep existing refresh token
      await _authService.setAccessToken(event.accessToken);
    }

    // Update state to validated
    emit(AuthStateData(
      state: AuthState.validated,
      validatedAt: DateTime.now(),
      retryCount: 0,
    ));
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthStateData> emit,
  ) async {
    _logger.info('[AuthBloc] Logout requested');

    // Clear auth data
    await _authService.clearAuthData();

    // Reset state
    _retryTimer?.cancel();
    emit(AuthStateData(state: AuthState.unauthenticated));
  }

  Future<void> _onServerUnavailable(
    AuthServerUnavailable event,
    Emitter<AuthStateData> emit,
  ) async {
    _logger.info('[AuthBloc] Server unavailable');

    if (event.allowOfflineMode) {
      emit(state.copyWith(
        state: AuthState.offlineMode,
        errorMessage: 'Mode offline - Fitur terbatas tersedia',
      ));
    } else {
      emit(state.copyWith(
        state: AuthState.serverUnavailable,
        errorMessage: ErrorMessageResolver.genericNetworkError,
      ));
      _startRetryTimer();
    }
  }

  Future<void> _onRetryValidation(
    AuthRetryValidation event,
    Emitter<AuthStateData> emit,
  ) async {
    _logger.info('[AuthBloc] Manual retry requested');
    _retryTimer?.cancel();
    add(AuthValidateRequested(forceRetry: true));
  }

  Future<void> _onEnterOfflineMode(
    AuthEnterOfflineMode event,
    Emitter<AuthStateData> emit,
  ) async {
    _logger.info('[AuthBloc] Entering offline mode');
    _retryTimer?.cancel();
    emit(state.copyWith(
      state: AuthState.offlineMode,
      errorMessage: null,
    ));
  }

  /// Classify validation exception to determine next action
  TokenValidationResult _classifyValidationException(dynamic error) {
    final errorMsg = error.toString().toLowerCase();

    // Network/timeout errors
    if (errorMsg.contains('connection refused') ||
        errorMsg.contains('connection reset') ||
        errorMsg.contains('failed host lookup') ||
        errorMsg.contains('network is unreachable') ||
        errorMsg.contains('timeout') ||
        errorMsg.contains('socket') ||
        error is TimeoutException) {
      return TokenValidationResult.networkError;
    }

    // Auth failures (401, 403, 404)
    if (errorMsg.contains('401') ||
        errorMsg.contains('403') ||
        errorMsg.contains('404') ||
        errorMsg.contains('unauthorized') ||
        errorMsg.contains('invalid token') ||
        errorMsg.contains('expired token') ||
        errorMsg.contains('user not found')) {
      return TokenValidationResult.invalid;
    }

    // Server errors (500, 502, 503)
    if (errorMsg.contains('500') ||
        errorMsg.contains('502') ||
        errorMsg.contains('503') ||
        errorMsg.contains('server error')) {
      return TokenValidationResult.serverError;
    }

    // Default to network error for unknown errors
    // (better to keep user logged in than log them out incorrectly)
    _logger.warning('[AuthBloc] Unknown error type, treating as network error: $error');
    return TokenValidationResult.networkError;
  }

  /// Start automatic retry timer
  void _startRetryTimer() {
    _retryTimer?.cancel();

    // Exponential backoff: 10s, 20s, 30s max
    final delaySeconds = [10, 20, 30][state.retryCount.clamp(0, 2)];

    _logger.info('[AuthBloc] Starting retry timer: ${delaySeconds}s');

    _retryTimer = Timer(Duration(seconds: delaySeconds), () {
      _logger.info('[AuthBloc] Retry timer fired, retrying validation');
      add(AuthValidateRequested(forceRetry: true));
    });
  }

  /// Cancel any pending retry timer
  void cancelRetryTimer() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }
}
