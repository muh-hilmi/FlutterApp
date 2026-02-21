import 'dart:math';

/// Utility for generating unique attendance codes
///
/// Generates 8-character alphanumeric codes (e.g., "A3F7K9M2")
/// Excludes ambiguous characters: 0, O, 1, I, L
class AttendanceCodeGenerator {
  // Alphanumeric characters excluding ambiguous ones
  static const String _chars = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  static final Random _random = Random();

  /// Generate a random 8-character attendance code
  ///
  /// Returns codes like: "A3F7K9M2", "P7R4N2KH"
  static String generate() {
    final buffer = StringBuffer();

    for (int i = 0; i < 8; i++) {
      buffer.write(_chars[_random.nextInt(_chars.length)]);
    }

    return buffer.toString();
  }

  /// Generate a unique code that doesn't exist in the given set
  ///
  /// Retries up to [maxRetries] times to avoid collisions
  static String generateUnique(
    Set<String> existingCodes, {
    int maxRetries = 100,
  }) {
    for (int i = 0; i < maxRetries; i++) {
      final code = generate();
      if (!existingCodes.contains(code)) {
        return code;
      }
    }

    // Fallback: Add timestamp suffix if collision persists
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${generate()}-${timestamp % 1000}';
  }

  /// Validate if a code matches the expected format
  ///
  /// Valid formats:
  /// - 8 uppercase alphanumeric characters (e.g., "A3F7K9M2")
  /// - 8 characters + timestamp suffix (e.g., "A3F7K9M2-123")
  static bool isValid(String code) {
    if (code.isEmpty) return false;

    // Check basic 8-character format
    if (code.length == 8) {
      return RegExp(r'^[A-Z0-9]{8}$').hasMatch(code);
    }

    // Check format with timestamp suffix
    if (code.contains('-')) {
      final parts = code.split('-');
      if (parts.length == 2 && parts[0].length == 8) {
        return RegExp(r'^[A-Z0-9]{8}$').hasMatch(parts[0]) &&
            RegExp(r'^\d+$').hasMatch(parts[1]);
      }
    }

    return false;
  }

  /// Normalize code to uppercase
  static String normalize(String code) {
    return code.trim().toUpperCase();
  }
}
