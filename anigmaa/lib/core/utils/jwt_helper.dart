import 'package:jwt_decode/jwt_decode.dart';

/// Helper for JWT token operations
class JwtHelper {
  /// Extract expiry time from JWT token
  ///
  /// Returns null if token is invalid or doesn't contain exp claim
  static DateTime? getExpiry(String token) {
    try {
      final payload = Jwt.parseJwt(token);
      final exp = payload['exp'] as int?;

      if (exp == null) return null;

      // Convert Unix timestamp (seconds) to DateTime
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (e) {
      return null;
    }
  }

  /// Check if JWT token is expired
  ///
  /// Returns true if token is expired or invalid
  /// Returns false if token is still valid
  static bool isExpired(String token) {
    final expiry = getExpiry(token);

    if (expiry == null) {
      // Invalid token, consider it expired
      return true;
    }

    // Add 30 second buffer to account for clock skew
    final now = DateTime.now().add(const Duration(seconds: 30));

    return now.isAfter(expiry);
  }

  /// Check if JWT token is about to expire (within 5 minutes)
  ///
  /// Returns true if token will expire in less than 5 minutes
  static bool isExpiringSoon(String token, {int minutes = 5}) {
    final expiry = getExpiry(token);

    if (expiry == null) {
      // Invalid token, consider it expiring
      return true;
    }

    final threshold = DateTime.now().add(Duration(minutes: minutes));

    return expiry.isBefore(threshold);
  }

  /// Get remaining time until token expires
  ///
  /// Returns null if token is invalid
  static Duration? getTimeUntilExpiry(String token) {
    final expiry = getExpiry(token);

    if (expiry == null) return null;

    final now = DateTime.now();

    if (expiry.isBefore(now)) {
      return Duration.zero;
    }

    return expiry.difference(now);
  }
}
