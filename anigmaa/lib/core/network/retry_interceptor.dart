import 'dart:async';
import 'dart:math';
import 'package:dio/dio.dart';
import 'error_classifier.dart';
import '../utils/app_logger.dart';

/// Details of a pending request for retry
class _PendingRequest {
  final RequestOptions requestOptions;
  final ErrorInterceptorHandler handler;

  _PendingRequest({
    required this.requestOptions,
    required this.handler,
  });
}

/// Interceptor that automatically retries failed requests with exponential backoff
///
/// Features:
/// - Distinguishes between retryable and non-retryable errors
/// - Exponential backoff: 2s, 4s, 8s, ...
/// - Max retry limit per request
/// - Queues requests when server is completely down
/// - Flushes queue when network recovers
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration initialBackoff;
  final Duration maxBackoff;
  final AppLogger _logger = AppLogger();

  /// Pending requests waiting for network recovery
  final List<_PendingRequest> _pendingRequests = [];

  /// Flag to prevent multiple retry cycles at once
  bool _isProcessingQueue = false;

  /// Stream controller for network status changes
  final StreamController<NetworkStatus> _statusController =
      StreamController.broadcast();

  /// Stream of network status changes
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 3,
    this.initialBackoff = const Duration(seconds: 2),
    this.maxBackoff = const Duration(seconds: 30),
  }) {
    // Listen for network status changes to retry pending requests
    statusStream.listen((status) {
      if (status == NetworkStatus.online) {
        _flushPendingRequests();
      }
    });
  }

  /// Notify that network is online (triggers retry of pending requests)
  void notifyNetworkOnline() {
    _statusController.add(NetworkStatus.online);
  }

  /// Notify that network is offline
  void notifyNetworkOffline() {
    _statusController.add(NetworkStatus.offline);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Initialize retry count if not present
    if (!options.extra.containsKey('_retryCount')) {
      options.extra['_retryCount'] = 0;
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Classify the error
    final networkError = ErrorClassifier.classify(err);

    // Get current retry count
    final currentRetry = err.requestOptions.extra['_retryCount'] as int? ?? 0;

    // If not retryable, pass through immediately
    if (!networkError.isRetryable) {
      _logger.debug('[Retry] Not retryable: ${networkError.type}');
      handler.next(err);
      return;
    }

    // If auth error, let AuthInterceptor handle it
    if (networkError.type == ErrorType.auth) {
      _logger.debug('[Retry] Auth error, passing to AuthInterceptor');
      handler.next(err);
      return;
    }

    // Check if this is an auth/login request - use faster retry strategy
    final path = err.requestOptions.path.toLowerCase();
    final isAuthRequest = path.contains('/auth/') || path.contains('/login');

    // For auth requests, max 1 retry with 1s delay (total ~2s instead of ~14s)
    final effectiveMaxRetries = isAuthRequest ? 1 : maxRetries;

    // Check if we've exceeded max retries (auth requests cap at 1)
    if (currentRetry >= effectiveMaxRetries) {
      _logger.warning(
        '[Retry] Max retries ($maxRetries) exceeded for ${err.requestOptions.path}',
      );

      // Don't queue auth/login requests - let them fail immediately
      // This prevents slow "try again" experience on login
      final path = err.requestOptions.path.toLowerCase();
      final isAuthRequest = path.contains('/auth/') || path.contains('/login');

      if (isAuthRequest) {
        _logger.info('[Retry] Auth request failed, not queuing - let user retry manually');
        handler.next(err);
        return;
      }

      // Queue for later retry if it's a network error (only for non-auth requests)
      if (networkError.type == ErrorType.network ||
          networkError.type == ErrorType.timeout) {
        _logger.info('[Retry] Queueing request for ${err.requestOptions.path}');
        _pendingRequests.add(_PendingRequest(
          requestOptions: err.requestOptions,
          handler: handler,
        ));
        // Don't call handler.next - request is queued
        return;
      }

      handler.next(err);
      return;
    }

    // Calculate backoff duration with exponential increase
    final backoffDuration = _calculateBackoff(currentRetry);

    _logger.info(
      '[Retry] Attempt ${currentRetry + 1}/$maxRetries for ${err.requestOptions.path} '
      'after ${backoffDuration.inSeconds}s',
    );

    // Wait before retrying
    await Future.delayed(backoffDuration);

    // Increment retry count
    err.requestOptions.extra['_retryCount'] = currentRetry + 1;

    try {
      // Clone the request options
      final retryOptions = err.requestOptions;

      // Retry the request
      final response = await dio.fetch(retryOptions);

      _logger.info('[Retry] Success on attempt ${currentRetry + 1}');
      handler.resolve(response);
    } catch (retryError) {
      _logger.error('[Retry] Attempt $currentRetry failed', retryError);

      // The retry failed, which will trigger onError again
      handler.next(retryError as DioException);
    }
  }

  /// Calculate exponential backoff duration
  Duration _calculateBackoff(int retryAttempt) {
    final exponential = min(pow(2, retryAttempt).toDouble(), maxBackoff.inSeconds.toDouble());
    final seconds = (initialBackoff.inSeconds * exponential).toInt().clamp(
          initialBackoff.inSeconds,
          maxBackoff.inSeconds,
        );
    // Add jitter (±20% randomness to prevent thundering herd)
    final jitter = (seconds * 0.2 * (Random().nextDouble() - 0.5)).toInt();
    return Duration(seconds: seconds + jitter);
  }

  /// Retry all pending requests when network recovers
  Future<void> _flushPendingRequests() async {
    if (_pendingRequests.isEmpty || _isProcessingQueue) {
      return;
    }

    _isProcessingQueue = true;
    _logger.info('[Retry] Flushing ${_pendingRequests.length} pending requests');

    final requests = List<_PendingRequest>.from(_pendingRequests);
    _pendingRequests.clear();

    for (final pending in requests) {
      try {
        // Reset retry count for fresh retry
        pending.requestOptions.extra['_retryCount'] = 0;

        final response = await dio.fetch(pending.requestOptions);
        pending.handler.resolve(response);
        _logger.debug('[Retry] Successfully retried ${pending.requestOptions.path}');
      } catch (e) {
        _logger.error('[Retry] Failed to retry ${pending.requestOptions.path}', e);

        // Re-queue if still a retryable error
        final networkError = ErrorClassifier.classify(e);
        if (networkError.isRetryable) {
          _pendingRequests.add(pending);
        } else {
          // Non-retryable error, pass through
          pending.handler.next(e as DioException);
        }
      }
    }

    _isProcessingQueue = false;

    // If any requests were re-queued, flush again after a delay
    if (_pendingRequests.isNotEmpty) {
      await Future.delayed(const Duration(seconds: 5));
      _flushPendingRequests();
    }
  }

  /// Clear all pending requests
  void clearPendingRequests() {
    _logger.info('[Retry] Clearing ${_pendingRequests.length} pending requests');
    for (final pending in _pendingRequests) {
      pending.handler.next(
        DioException(
          requestOptions: pending.requestOptions,
          error: 'Request cancelled: pending requests cleared',
          type: DioExceptionType.unknown,
        ),
      );
    }
    _pendingRequests.clear();
  }

  /// Get count of pending requests
  int get pendingRequestCount => _pendingRequests.length;

  void dispose() {
    _statusController.close();
  }
}

/// Network status for retry triggering
enum NetworkStatus { online, offline }
