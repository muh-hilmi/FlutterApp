import 'dart:async';
import 'package:flutter/foundation.dart';
import 'connectivity_service.dart';
import 'auth_service.dart';
import '../utils/app_logger.dart';
import '../../data/datasources/auth_remote_datasource.dart';

/// Service for automatically refreshing tokens and data when connectivity is restored
///
/// Features:
/// - Monitors connectivity changes
/// - Auto-refreshes access token when connection is restored (if needed)
/// - Silent retry mechanism for failed token refresh
/// - Non-blocking UI operations
class AutoRefreshService extends ChangeNotifier {
  final ConnectivityService _connectivityService;
  final AuthService _authService;
  final AuthRemoteDataSource _authDataSource;
  final AppLogger _logger = AppLogger();

  // Retry state
  Timer? _retryTimer;
  Timer? _connectivityCheckTimer;
  int _retryCount = 0;
  static const int _maxRetryCount = 5;
  static const Duration _retryInterval = Duration(seconds: 30);

  // Connectivity state tracking
  bool _wasOffline = false;

  AutoRefreshService({
    required ConnectivityService connectivityService,
    required AuthService authService,
    required AuthRemoteDataSource authDataSource,
  })  : _connectivityService = connectivityService,
        _authService = authService,
        _authDataSource = authDataSource {
    _init();
  }

  void _init() {
    // Initialize offline state
    _wasOffline = !_connectivityService.isOnline;

    // Start periodic connectivity check (every 10 seconds)
    _connectivityCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _checkConnectivityChange();
    });
  }

  void _checkConnectivityChange() {
    final isOnline = _connectivityService.isOnline;

    if (isOnline && _wasOffline) {
      // Connection restored - trigger auto refresh
      _logger.info('[AutoRefresh] Connection restored, triggering auto-refresh');
      _onConnectionRestored();
    }

    _wasOffline = !isOnline;
  }

  Future<void> _onConnectionRestored() async {
    // Cancel any pending retry timer
    _retryTimer?.cancel();
    _retryCount = 0;

    // Check if user has refresh token
    final hasRefreshToken = await _authService.hasRefreshToken;

    if (!hasRefreshToken) {
      _logger.debug('[AutoRefresh] No refresh token, skipping auto-refresh');
      return;
    }

    // Check if access token needs refresh
    final isTokenExpired = await _authService.isAccessTokenExpired();

    if (!isTokenExpired) {
      _logger.debug('[AutoRefresh] Access token still valid, skipping refresh');
      return;
    }

    // Attempt silent token refresh
    await _silentTokenRefresh();
  }

  Future<void> _silentTokenRefresh() async {
    try {
      _logger.info('[AutoRefresh] Attempting silent token refresh');

      final refreshToken = await _authService.refreshToken;

      if (refreshToken == null) {
        _logger.warning('[AutoRefresh] Refresh token is null');
        return;
      }

      // Attempt refresh with short timeout (5s)
      final authResponse = await _authDataSource.refreshToken(refreshToken).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Token refresh timeout');
        },
      );

      // Success - save new tokens
      await _authService.updateTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
      );

      _logger.info('[AutoRefresh] Token refresh successful');

      // Reset retry count on success
      _retryCount = 0;
      _retryTimer?.cancel();

      // TODO: Trigger feed refresh here
      // You can emit an event or call a callback to refresh feed data
      notifyListeners();

    } catch (e) {
      _logger.warning('[AutoRefresh] Token refresh failed: $e');

      final errorMsg = e.toString().toLowerCase();

      // Check if this is an auth error (401/403)
      final isAuthError = errorMsg.contains('401') ||
          errorMsg.contains('403') ||
          errorMsg.contains('unauthorized') ||
          errorMsg.contains('invalid token') ||
          errorMsg.contains('expired token');

      if (isAuthError) {
        // Auth error - stop retrying and clear tokens
        _logger.warning('[AutoRefresh] Auth error detected, stopping retry');
        _retryCount = 0;
        _retryTimer?.cancel();
        await _authService.clearAuthData();
        return;
      }

      // Network error - schedule retry
      _scheduleRetry();
    }
  }

  void _scheduleRetry() {
    // Check if we've exceeded max retries
    if (_retryCount >= _maxRetryCount) {
      _logger.warning('[AutoRefresh] Max retry count reached, stopping');
      _retryTimer?.cancel();
      return;
    }

    _retryCount++;
    _logger.info('[AutoRefresh] Scheduling retry $_retryCount/$_maxRetryCount in $_retryInterval');

    _retryTimer = Timer(_retryInterval, () {
      if (_connectivityService.isOnline) {
        _logger.info('[AutoRefresh] Retry timer fired');
        _silentTokenRefresh();
      } else {
        _logger.debug('[AutoRefresh] Still offline, skipping retry');
        // Keep retry timer running - will retry when connection is restored
      }
    });
  }

  /// Public method to manually trigger refresh (e.g., pull-to-refresh)
  Future<bool> manualRefresh() async {
    _logger.info('[AutoRefresh] Manual refresh requested');

    if (!_connectivityService.isOnline) {
      _logger.warning('[AutoRefresh] Cannot refresh - offline');
      return false;
    }

    await _silentTokenRefresh();
    return true;
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _connectivityCheckTimer?.cancel();
    super.dispose();
  }
}
