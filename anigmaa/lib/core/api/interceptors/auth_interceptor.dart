import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_logger.dart';
import '../../network/error_classifier.dart';
import '../../../main.dart' show navigatorKey;

/// Callback function type for token refresh success notification
typedef OnTokenRefreshedCallback = void Function(String accessToken, String? refreshToken);

/// Interceptor to handle authentication tokens
/// Automatically attaches Bearer token to requests and refreshes expired tokens
///
/// Key features:
/// - Distinguishes between auth errors and network errors
/// - Only logs out on actual auth failure, not network issues
/// - Queues requests during token refresh
/// - Prevents logout when server is temporarily unreachable
/// - Rate limits 401 errors to prevent infinite loops
/// - Notits AuthBloc when token is successfully refreshed
class AuthInterceptor extends Interceptor {
  final _logger = AppLogger();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Callback called when token is successfully refreshed
  OnTokenRefreshedCallback? onTokenRefreshed;

  /// Creates a new AuthInterceptor
  ///
  /// [onTokenRefreshed] is called when token is successfully refreshed,
  /// allowing the AuthBloc to update its state
  AuthInterceptor({this.onTokenRefreshed});

  // Static state to prevent duplicate refresh attempts across instances
  static bool _isRedirectingToLogin = false;
  static bool _isRefreshing = false;

  // Request queue: stores pending requests during refresh
  final List<_QueuedRequest> _requestQueue = [];

  // Rate limiting for 401 errors (prevent infinite retry loops)
  static int _consecutive401Count = 0;
  static DateTime? _last401Time;
  static const _maxConsecutive401 = 3;
  static final _resetDurationAfter401Error = Duration(minutes: 1);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final token = await _secureStorage.read(key: 'access_token');

      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    } catch (e) {
      _logger.error('Failed to read auth token', e);
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Classify the error first - this is critical for proper handling
    final networkError = ErrorClassifier.classify(err);

    // Only handle auth errors (401)
    // Network errors (connection refused, timeout) are handled by RetryInterceptor
    if (networkError.type != ErrorType.auth) {
      _logger.debug(
        '[Auth] Not an auth error (type: ${networkError.type}), '
        'passing to next interceptor',
      );
      handler.next(err);
      return;
    }

    // At this point, we know it's a 401
    _logger.info('🔄 401 Unauthorized detected, attempting token refresh...');

    // Rate limiting: check for too many consecutive 401s
    final now = DateTime.now();
    if (_last401Time != null &&
        now.difference(_last401Time!) > _resetDurationAfter401Error) {
      _consecutive401Count = 0; // Reset counter after time window
    }
    _last401Time = now;
    _consecutive401Count++;

    if (_consecutive401Count > _maxConsecutive401) {
      _logger.error(
        '❌ Too many consecutive 401s ($_consecutive401Count), '
        'forcing logout to prevent infinite loop',
      );
      await _logoutUser(showLoginDialog: true);
      handler.next(err);
      return;
    }

    // Skip if already refreshing to prevent infinite loops
    if (_isRefreshing) {
      _logger.debug('⏳ Refresh already in progress, queuing request');
      _requestQueue.add(_QueuedRequest(
        requestOptions: err.requestOptions,
        handler: handler,
      ));
      return;
    }

    _isRefreshing = true;

    try {
      final refreshToken = await _secureStorage.read(key: 'refresh_token');

      if (refreshToken == null || refreshToken.isEmpty) {
        _logger.warning('❌ No refresh token available - logging out');
        await _logoutUser();
        return;
      }

      // Create a new Dio instance for refresh to avoid interceptor loops
      final refreshDio = Dio();
      refreshDio.options.baseUrl = _getBaseUrl(err.requestOptions);
      refreshDio.options.headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $refreshToken',
      };
      refreshDio.options.connectTimeout = const Duration(seconds: 10);
      refreshDio.options.receiveTimeout = const Duration(seconds: 10);

      _logger.debug('[Auth] Calling /auth/refresh...');

      final refreshResponse = await refreshDio.post(
        '/auth/refresh',
        data: {
          'refresh_token': refreshToken,
        },
      );

      if (refreshResponse.statusCode == 200) {
        // Reset 401 counter on successful refresh
        _consecutive401Count = 0;

        final data = refreshResponse.data['data'] ?? refreshResponse.data;
        final newAccessToken = data['accessToken'] ?? data['access_token'];
        final newRefreshToken = data['refreshToken'] ?? data['refresh_token'];

        if (newAccessToken != null) {
          // Store new tokens
          await _secureStorage.write(key: 'access_token', value: newAccessToken);
          if (newRefreshToken != null) {
            await _secureStorage.write(key: 'refresh_token', value: newRefreshToken);
          }

          _logger.info('✅ Token refreshed successfully');

          // Notify AuthBloc that token was refreshed (so it can update state from offlineMode)
          onTokenRefreshed?.call(newAccessToken, newRefreshToken);

          // Retry the original request with new token
          final originalRequest = err.requestOptions;
          originalRequest.headers['Authorization'] = 'Bearer $newAccessToken';

          try {
            final response = await refreshDio.fetch(originalRequest);
            handler.resolve(response);

            // Process queued requests with new token
            await _processQueuedRequests(newAccessToken);
            return;
          } catch (retryError) {
            _logger.error('❌ Failed to retry original request after refresh', retryError);
            // Still process queue - other requests might succeed
            await _processQueuedRequests(newAccessToken);
          }
        }
      } else {
        _logger.warning('❌ Token refresh failed with status: ${refreshResponse.statusCode}');
      }
    } catch (refreshError) {
      // Check if refresh failed due to network issues
      final refreshNetworkError = ErrorClassifier.classify(refreshError);

      if (refreshNetworkError.type == ErrorType.network ||
          refreshNetworkError.type == ErrorType.timeout) {
        // Network issue during refresh - don't logout!
        // The RetryInterceptor will handle retrying the request
        _logger.warning(
          '⚠️ Token refresh failed due to network issue - '
          'will retry. NOT logging out.',
        );
        // Don't call handler.next(err) - let RetryInterceptor handle retry
        // But we need to mark refreshing as complete
        _isRefreshing = false;

        // Pass the original error through so RetryInterceptor can retry
        handler.next(err);
        return;
      }

      _logger.error('❌ Token refresh failed (non-network error)', refreshError);
    } finally {
      _isRefreshing = false;

      // If we haven't processed the queue (refresh failed), notify handlers
      if (_requestQueue.isNotEmpty) {
        _logger.warning('[Auth] Refresh failed, notifying ${_requestQueue.length} queued requests');
        for (final queued in _requestQueue) {
          queued.handler.next(err);
        }
        _requestQueue.clear();
      }
    }

    // If we get here, refresh genuinely failed (not a network issue)
    _logger.warning('🔒 Token refresh failed - logging out user');
    await _logoutUser();
    handler.next(err);
  }

  /// Process all queued requests with the new token
  Future<void> _processQueuedRequests(String newToken) async {
    if (_requestQueue.isEmpty) return;

    _logger.info('[Auth] Processing ${_requestQueue.length} queued requests');

    final requests = List<_QueuedRequest>.from(_requestQueue);
    _requestQueue.clear();

    for (final queued in requests) {
      try {
        queued.requestOptions.headers['Authorization'] = 'Bearer $newToken';
        final dio = Dio();
        final response = await dio.fetch(queued.requestOptions);
        queued.handler.resolve(response);
      } catch (e) {
        _logger.error('[Auth] Queued request failed', e);
        queued.handler.next(e as DioException);
      }
    }
  }

  /// Extract base URL from request options
  String _getBaseUrl(RequestOptions options) {
    // Try to get from options
    if (options.baseUrl.isNotEmpty) {
      return options.baseUrl;
    }

    // Fallback to known base URLs
    // Check if we can determine from the path
    if (options.path.contains('/api/v1') ||
        options.path.contains('/auth') ||
        options.path.contains('/users')) {
      // Assuming localhost for development
      return 'http://localhost:8123/api/v1';
    }

    // Ultimate fallback
    return 'http://localhost:8123/api/v1';
  }

  /// Log out the user
  Future<void> _logoutUser({bool showLoginDialog = true}) async {
    if (_isRedirectingToLogin) return;

    _isRedirectingToLogin = true;
    _logger.warning('🔒 Logging out user - token refresh failed');

    // Clear tokens
    try {
      await _secureStorage.delete(key: 'access_token');
      await _secureStorage.delete(key: 'refresh_token');
      _logger.info('✅ Tokens cleared from secure storage');
    } catch (e) {
      _logger.error('Failed to clear tokens', e);
    }

    // Clear SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', false);
      await prefs.remove('user_email');
      await prefs.remove('user_name');
      await prefs.remove('user_id');
      _logger.info('✅ User preferences cleared');
    } catch (e) {
      _logger.error('Failed to clear preferences', e);
    }

    // Reset 401 counter
    _consecutive401Count = 0;
    _last401Time = null;

    // Navigate to login screen
    if (!showLoginDialog) {
      _isRedirectingToLogin = false;
      return;
    }

    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      _logger.info('🔄 Showing login dialog');

      Future.microtask(() async {
        if (!context.mounted) return;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.lock_clock, color: Colors.orange),
                SizedBox(width: 12),
                Text('Sesi Berakhir'),
              ],
            ),
            content: const Text(
              'Sesi kamu telah berakhir. Silakan login kembali untuk melanjutkan.',
              style: TextStyle(fontSize: 15),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFBBC863),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );

        _isRedirectingToLogin = false;
      });
    } else {
      _isRedirectingToLogin = false;
    }
  }
}

/// Class to hold queued request data
class _QueuedRequest {
  final RequestOptions requestOptions;
  final ErrorInterceptorHandler handler;

  _QueuedRequest({
    required this.requestOptions,
    required this.handler,
  });
}
