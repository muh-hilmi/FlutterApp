import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import 'app_logger.dart';

/// Helper untuk mengecek koneksi sebelum user action
///
/// Usage:
/// ```dart
/// if (!await checkConnectivityBeforeAction(context)) {
///   return; // Stop action execution
/// }
/// // Proceed with action...
/// ```
Future<bool> checkConnectivityBeforeAction(BuildContext context) async {
  try {
    // Cek instance ConnectivityService
    final connectivityService = ConnectivityService();

    if (!connectivityService.isOnline) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Kamu offline. Aktifkan internet dulu ya!'),
            backgroundColor: Color(0xFFFF0055),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      AppLogger().warning('[OfflineHelper] Action blocked - user is offline');
      return false;
    }

    return true;
  } catch (e) {
    AppLogger().error('[OfflineHelper] Error checking connectivity: $e');
    // Jika error checking, allow action (better false positive than block legitimate action)
    return true;
  }
}

/// Helper untuk cek connectivity tanpa context (untuk non-UI actions)
bool isConnected() {
  try {
    return ConnectivityService().isOnline;
  } catch (e) {
    AppLogger().error('[OfflineHelper] Error checking connectivity (no context): $e');
    return true; // Allow if error
  }
}
