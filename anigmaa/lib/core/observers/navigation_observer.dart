import 'package:flutter/material.dart';
import '../utils/app_logger.dart';

/// Observer untuk tracking semua navigasi user dalam aplikasi
class AppNavigationObserver extends NavigatorObserver {
  final AppLogger _logger = AppLogger();

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logNavigation('PUSH', route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _logNavigation('POP', route, previousRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);
    _logNavigation('REMOVE', route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _logNavigation('REPLACE', newRoute, oldRoute);
  }

  void _logNavigation(String action, Route<dynamic>? route, Route<dynamic>? previousRoute) {
    final routeName = _getRouteName(route);
    final previousRouteName = _getRouteName(previousRoute);

    final logMessage = '[$action] Navigation: $previousRouteName -> $routeName';
    _logger.info(logMessage);

    // Log route settings jika ada
    if (route?.settings.arguments != null) {
      _logger.debug('Route arguments: ${route?.settings.arguments}');
    }
  }

  String _getRouteName(Route<dynamic>? route) {
    if (route == null) return 'null';

    // Coba ambil dari settings name dulu
    if (route.settings.name != null && route.settings.name!.isNotEmpty) {
      return route.settings.name!;
    }

    // Fallback ke route type
    return route.toString();
  }
}
