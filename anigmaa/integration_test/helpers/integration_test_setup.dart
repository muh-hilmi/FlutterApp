/// ============================================================
/// INTEGRATION TEST SETUP HELPER
/// ============================================================
///
/// Helper ini menyiapkan state app sebelum test dijalankan.
/// Karena integration test jalan di emulator asli, kita pakai
/// SharedPreferences yang nyata (bukan mock).
/// ============================================================

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TestSetup {
  // ─── Simulasi: User belum pernah buka app ─────────────────────────────────
  static Future<void> freshInstall() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    const storage = FlutterSecureStorage();
    await storage.deleteAll();
  }

  // ─── Simulasi: User sudah lihat onboarding tapi belum login ───────────────
  static Future<void> seenOnboardingNotLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool('has_seen_onboarding', true);

    const storage = FlutterSecureStorage();
    await storage.deleteAll();
  }

  // ─── Simulasi: User belum lihat onboarding (first time) ───────────────────
  static Future<void> firstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await prefs.setBool('has_seen_onboarding', false);

    const storage = FlutterSecureStorage();
    await storage.deleteAll();
  }

  // ─── Simulasi: User sudah login dengan token valid ────────────────────────
  /// CATATAN: Backend harus menerima token ini!
  /// Gunakan hanya kalau backend running dan token ini valid.
  static Future<void> loggedInWithToken({
    required String accessToken,
    required String refreshToken,
    String userId = 'test-user-123',
    String userEmail = 'test@example.com',
    String userName = 'Test User',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', true);
    await prefs.setBool('has_seen_onboarding', true);
    await prefs.setString('user_id', userId);
    await prefs.setString('user_email', userEmail);
    await prefs.setString('user_name', userName);

    const storage = FlutterSecureStorage();
    await storage.write(key: 'access_token', value: accessToken);
    await storage.write(key: 'refresh_token', value: refreshToken);
  }
}
