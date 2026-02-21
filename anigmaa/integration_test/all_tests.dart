/// ============================================================
/// ALL INTEGRATION TESTS — RUNNER UTAMA
/// ============================================================
///
/// Jalankan semua integration test sekaligus:
///
///   flutter test integration_test/all_tests.dart -d <device_id>
///
/// Atau run satu per satu (lebih mudah debug):
///
///   flutter test integration_test/flows/01_auth_flow_test.dart -d <device_id>
///   flutter test integration_test/flows/02_navigation_test.dart -d <device_id>
///   flutter test integration_test/flows/03_discover_test.dart -d <device_id>
///   flutter test integration_test/flows/04_profile_test.dart -d <device_id>
///
/// Lihat device yang tersedia:
///   flutter devices
/// ============================================================

import 'flows/01_auth_flow_test.dart' as auth_flow;
import 'flows/02_navigation_test.dart' as navigation;
import 'flows/03_discover_test.dart' as discover;
import 'flows/04_profile_test.dart' as profile;

void main() {
  auth_flow.main();
  navigation.main();
  discover.main();
  profile.main();
}
