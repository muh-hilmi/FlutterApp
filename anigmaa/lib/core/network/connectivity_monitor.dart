import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import '../constants/app_config.dart';
import '../utils/app_logger.dart';
import 'retry_interceptor.dart';

/// Monitor for network connectivity changes with automatic health check
///
/// Features:
/// - Listens to platform connectivity changes (wifi, mobile, none)
/// - Performs health check to verify actual server reachability
/// - Triggers retry of pending requests when network recovers
/// - Distinguishes between "device connected" and "server reachable"
class ConnectivityMonitor {
  static ConnectivityMonitor? _instance;
  static ConnectivityMonitor get instance {
    _instance ??= ConnectivityMonitor._internal();
    return _instance!;
  }

  ConnectivityMonitor._internal();

  final Connectivity _connectivity = Connectivity();
  final AppLogger _logger = AppLogger();

  /// Dio instance for health checks (separate from main client)
  late final Dio _healthCheckDio;

  /// Stream controller for network status
  final StreamController<NetworkStatus> _statusController =
      StreamController.broadcast();

  /// Stream of network status changes
  Stream<NetworkStatus> get statusStream => _statusController.stream;

  /// Current network status
  NetworkStatus _currentStatus = NetworkStatus.offline;

  /// Get current network status
  NetworkStatus get currentStatus => _currentStatus;

  /// Retry interceptor to notify of network changes
  RetryInterceptor? _retryInterceptor;

  /// Timer for periodic health checks
  Timer? _healthCheckTimer;

  /// Subscription to connectivity changes
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// Whether the monitor has been initialized
  bool _isInitialized = false;

  /// Register the retry interceptor to be notified of network changes
  void registerRetryInterceptor(RetryInterceptor interceptor) {
    _retryInterceptor = interceptor;
  }

  /// Initialize the connectivity monitor
  Future<void> initialize() async {
    if (_isInitialized) return;

    _logger.info('[Connectivity] Initializing connectivity monitor');

    // Initialize health check Dio instance
    _healthCheckDio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        sendTimeout: const Duration(seconds: 5),
      ),
    );

    // Check initial connectivity status
    final initialResult = await _connectivity.checkConnectivity();
    await _handleConnectivityChange(initialResult);

    // Listen to connectivity changes
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );

    _isInitialized = true;
    _logger.info('[Connectivity] Monitor initialized');
  }

  /// Handle connectivity change from platform
  Future<void> _handleConnectivityChange(List<ConnectivityResult> results) async {
    _logger.info('[Connectivity] Connectivity changed: $results');

    // Check if we have any connectivity (not none)
    final hasConnection = results.any(
      (result) => result != ConnectivityResult.none,
    );

    if (!hasConnection) {
      // No connectivity at all
      if (_currentStatus != NetworkStatus.offline) {
        _logger.info('[Connectivity] Network offline');
        _setStatus(NetworkStatus.offline);
        _retryInterceptor?.notifyNetworkOffline();
      }
      return;
    }

    // Platform says we have connectivity, but we need to verify with health check
    await _performHealthCheck();
  }

  /// Perform health check to verify server is actually reachable
  ///
  /// Uses a lightweight HEAD request to the API root.
  /// Any response (including 404) means the server is reachable.
  /// Only connection errors mean the server is down.
  Future<void> _performHealthCheck() async {
    _logger.debug('[Connectivity] Performing health check...');

    try {
      // Use HEAD request to root - lightweight and doesn't require auth
      // Any HTTP response means server is reachable
      final response = await _healthCheckDio.head(
        '/',
        options: Options(
          validateStatus: (status) => status != null && status < 600,
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      ).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw Exception('Health check timeout');
        },
      );

      // If we get ANY response from the server (even 404, 401, 500),
      // it means the server is reachable
      if (response.statusCode != null) {
        if (_currentStatus != NetworkStatus.online) {
          _logger.info(
            '[Connectivity] Server reachable (${response.statusCode}) - Network online',
          );
          _setStatus(NetworkStatus.online);
          _retryInterceptor?.notifyNetworkOnline();
        }
        return;
      }
    } on DioException catch (e) {
      // DioException with connection error = server is actually down
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        if (_currentStatus != NetworkStatus.offline) {
          _logger.info('[Connectivity] Server unreachable');
          _setStatus(NetworkStatus.offline);
          _retryInterceptor?.notifyNetworkOffline();
        }
        return;
      }

      // Other errors (like 4xx, 5xx responses) mean server is reachable
      if (_currentStatus != NetworkStatus.online) {
        _logger.info('[Connectivity] Server reachable - Network online');
        _setStatus(NetworkStatus.online);
        _retryInterceptor?.notifyNetworkOnline();
      }
      return;
    } catch (e) {
      // Non-Dio errors - likely no internet
      _logger.debug('[Connectivity] Health check error: $e');
    }

    // Default to offline if we couldn't determine status
    if (_currentStatus != NetworkStatus.offline) {
      _logger.info('[Connectivity] Assuming offline (no response)');
      _setStatus(NetworkStatus.offline);
      _retryInterceptor?.notifyNetworkOffline();
    }
  }

  /// Set network status
  void _setStatus(NetworkStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// Manually trigger a health check (call when you suspect network recovery)
  Future<void> checkNow() async {
    await _performHealthCheck();
  }

  /// Start periodic health checks (useful for long-running app)
  void startPeriodicHealthCheck({Duration interval = const Duration(minutes: 1)}) {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(interval, (_) {
      _performHealthCheck();
    });
    _logger.info('[Connectivity] Started periodic health check (every ${interval.inSeconds}s)');
  }

  /// Stop periodic health checks
  void stopPeriodicHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;
    _logger.info('[Connectivity] Stopped periodic health check');
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _healthCheckTimer?.cancel();
    _statusController.close();
    _isInitialized = false;
    _logger.info('[Connectivity] Monitor disposed');
  }
}
