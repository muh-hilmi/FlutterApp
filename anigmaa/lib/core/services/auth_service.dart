import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/jwt_helper.dart';

class AuthService {
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyHasSeenOnboarding = 'has_seen_onboarding';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserName = 'user_name';
  static const String _keyUserId = 'user_id';

  // Public so AuthInterceptor can use the same keys — single source of truth
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';

  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;

  AuthService(this._prefs, this._secureStorage);

  // Login state (non-sensitive, can stay in SharedPreferences)
  bool get isLoggedIn => _prefs.getBool(_keyIsLoggedIn) ?? false;

  Future<void> setLoggedIn(bool value) async {
    await _prefs.setBool(_keyIsLoggedIn, value);
  }

  // Onboarding state
  bool get hasSeenOnboarding => _prefs.getBool(_keyHasSeenOnboarding) ?? false;

  Future<void> setHasSeenOnboarding(bool value) async {
    await _prefs.setBool(_keyHasSeenOnboarding, value);
  }

  // User data (non-sensitive)
  String? get userEmail => _prefs.getString(_keyUserEmail);

  Future<void> setUserEmail(String email) async {
    await _prefs.setString(_keyUserEmail, email);
  }

  String? get userName => _prefs.getString(_keyUserName);

  Future<void> setUserName(String name) async {
    await _prefs.setString(_keyUserName, name);
  }

  String? get userId => _prefs.getString(_keyUserId);

  Future<void> setUserId(String id) async {
    await _prefs.setString(_keyUserId, id);
  }

  // Login
  Future<void> login(String email, String name) async {
    await setLoggedIn(true);
    await setUserEmail(email);
    await setUserName(name);
  }

  // Token management (SECURE - using FlutterSecureStorage)
  Future<String?> get accessToken async {
    return await _secureStorage.read(key: keyAccessToken);
  }

  Future<void> setAccessToken(String token) async {
    await _secureStorage.write(key: keyAccessToken, value: token);
  }

  Future<String?> get refreshToken async {
    return await _secureStorage.read(key: keyRefreshToken);
  }

  Future<void> setRefreshToken(String token) async {
    await _secureStorage.write(key: keyRefreshToken, value: token);
  }

  // Save auth data from API response
  Future<void> saveAuthData({
    required String userId,
    required String email,
    required String name,
    required String accessToken,
    required String refreshToken,
  }) async {
    await setLoggedIn(true);
    await setUserId(userId);
    await setUserEmail(email);
    await setUserName(name);
    await setAccessToken(accessToken);
    await setRefreshToken(refreshToken);
  }

  // Update tokens (useful for token refresh)
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await setAccessToken(accessToken);
    await setRefreshToken(refreshToken);
  }

  // Logout
  Future<void> logout() async {
    await setLoggedIn(false);
    await _prefs.remove(_keyUserEmail);
    await _prefs.remove(_keyUserName);
    await _prefs.remove(_keyUserId);
    await _secureStorage.delete(key: keyAccessToken);
    await _secureStorage.delete(key: keyRefreshToken);
  }

  // Clear all data (for complete reset)
  Future<void> clearAll() async {
    await _prefs.clear();
    await _secureStorage.deleteAll();
  }

  // Clear auth data (tokens only)
  Future<void> clearAuthData() async {
    await setLoggedIn(false);
    await _secureStorage.delete(key: keyAccessToken);
    await _secureStorage.delete(key: keyRefreshToken);
  }

  // Check if token exists
  Future<bool> get hasValidToken async {
    final token = await accessToken;
    return token != null && token.isNotEmpty;
  }

  // Check if refresh token exists (for offline-first auth)
  Future<bool> get hasRefreshToken async {
    final token = await refreshToken;
    return token != null && token.isNotEmpty;
  }

  // Check if access token is expired (using JWT expiry claim)
  Future<bool> isAccessTokenExpired() async {
    final token = await accessToken;

    if (token == null || token.isEmpty) {
      return true; // No token = expired
    }

    return JwtHelper.isExpired(token);
  }

  // Check if access token is expiring soon (within 5 minutes)
  Future<bool> isAccessTokenExpiringSoon({int minutes = 5}) async {
    final token = await accessToken;

    if (token == null || token.isEmpty) {
      return true; // No token = expiring
    }

    return JwtHelper.isExpiringSoon(token, minutes: minutes);
  }

  // Get remaining time until access token expires
  Future<Duration?> getAccessTokenTimeUntilExpiry() async {
    final token = await accessToken;

    if (token == null || token.isEmpty) {
      return null;
    }

    return JwtHelper.getTimeUntilExpiry(token);
  }
}
