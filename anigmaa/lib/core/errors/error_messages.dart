/// Centralized error message resolver for production-ready error handling
///
/// All user-facing error messages should come from here for consistency
/// and easy localization in the future.
class ErrorMessageResolver {
  const ErrorMessageResolver._();

  // ============================================
  // NETWORK ERRORS
  // ============================================

  /// Connection refused / Server not running
  static String get serverNotRunning {
    return 'Server sedang tidak dapat dihubungi.\n\n'
        'Kemungkinan server sedang dalam pemeliharaan. '
        'Silakan coba lagi dalam beberapa saat.';
  }

  /// Failed host lookup / No internet
  static String get noInternetConnection {
    return 'Tidak ada koneksi internet.\n\n'
        'Pastikan WiFi atau data seluler kamu telah aktif.';
  }

  /// Network unreachable
  static String get networkUnreachable {
    return 'Koneksi internet terputus.\n\n'
        'Periksa koneksi internet kamu dan coba lagi.';
  }

  /// Connection timeout
  static String get connectionTimeout {
    return 'Waktu koneksi habis.\n\n'
        'Server mungkin sedang sibuk. Silakan coba lagi.';
  }

  /// Request timeout
  static String get requestTimeout {
    return 'Permintaan terlalu lama.\n\n'
        'Server sedang merespon dengan lambat. '
        'Silakan coba lagi.';
  }

  /// Socket error / Connection interrupted
  static String get connectionInterrupted {
    return 'Koneksi terputus.\n\n'
        'Periksa koneksi internet kamu.';
  }

  /// SSL Certificate error
  static String get sslError {
    return 'Koneksi tidak aman.\n\n'
        'Periksa pengaturan waktu dan tanggal di perangkat kamu.';
  }

  /// Generic network error (fallback)
  static String get genericNetworkError {
    return 'Tidak dapat terhubung ke server.\n\n'
        'Periksa koneksi internet kamu dan coba lagi.';
  }

  // ============================================
  // SERVER ERRORS
  // ============================================

  /// Internal server error (500)
  static String get internalServerError {
    return 'Terjadi kesalahan pada server.\n\n'
        'Kami telah memperhatikan masalah ini. '
        'Silakan coba lagi nanti.';
  }

  /// Bad gateway (502)
  static String get badGateway {
    return 'Server sedang tidak dapat dihubungi.\n\n'
        'Silakan coba lagi dalam beberapa saat.';
  }

  /// Service unavailable (503)
  static String get serviceUnavailable {
    return 'Layanan sedang tidak tersedia.\n\n'
        'Kami sedang melakukan pemeliharaan. '
        'Silakan coba lagi nanti.';
  }

  /// Gateway timeout (504)
  static String get gatewayTimeout {
    return 'Server tidak merespon.\n\n'
        'Silakan coba lagi.';
  }

  /// Generic server error (fallback)
  static String get genericServerError {
    return 'Terjadi kesalahan pada server.\n\n'
        'Silakan coba lagi.';
  }

  // ============================================
  // AUTH ERRORS
  // ============================================

  /// Invalid credentials
  static String get invalidCredentials {
    return 'Email atau password salah.\n\n'
        'Periksa kembali dan coba lagi.';
  }

  /// Session expired
  static String get sessionExpired {
    return 'Sesi kamu telah berakhir.\n\n'
        'Silakan login kembali.';
  }

  /// Unauthorized / Not logged in
  static String get unauthorized {
    return 'Kamu belum login.\n\n'
        'Silakan login terlebih dahulu.';
  }

  /// Forbidden / No permission
  static String get forbidden {
    return 'Kamu tidak memiliki izin untuk mengakses halaman ini.';
  }

  /// Token invalid
  static String get tokenInvalid {
    return 'Sesi tidak valid.\n\n'
        'Silakan login kembali.';
  }

  // ============================================
  // CLIENT ERRORS
  // ============================================

  /// Bad request (400)
  static String get badRequest {
    return 'Permintaan tidak valid.\n\n'
        'Silakan coba lagi.';
  }

  /// Not found (404)
  static String get notFound {
    return 'Data tidak ditemukan.\n\n'
        'Mungkin sudah dihapus atau dipindahkan.';
  }

  /// Request cancelled
  static String get requestCancelled {
    return 'Permintaan dibatalkan.';
  }

  // ============================================
  // VALIDATION ERRORS
  // ============================================

  /// Invalid email format
  static String get invalidEmail {
    return 'Format email tidak valid.';
  }

  /// Weak password
  static String get weakPassword {
    return 'Password terlalu lemah.\n\n'
        'Gunakan kombinasi huruf dan angka.';
  }

  /// Required field empty
  static String requiredField(String fieldName) {
    return '$fieldName tidak boleh kosong.';
  }

  /// Invalid input format
  static String invalidFormat(String fieldName) {
    return 'Format $fieldName tidak valid.';
  }

  // ============================================
  // GENERIC ERRORS
  // ============================================

  /// Unknown error
  static String get unknownError {
    return 'Terjadi kesalahan tidak terduga.\n\n'
        'Silakan coba lagi.';
  }

  /// Something went wrong
  static String get somethingWentWrong {
    return 'Terjadi kesalahan.\n\n'
        'Silakan coba lagi.';
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Resolve error message from Failure type
  static String resolve(dynamic error) {
    if (error is String) {
      return error;
    }

    final errorStr = error.toString().toLowerCase();

    // Connection errors
    if (errorStr.contains('connection refused') ||
        errorStr.contains('errno') ||
        errorStr.contains('connect failed')) {
      return serverNotRunning;
    }

    // DNS / Host lookup errors
    if (errorStr.contains('failed host lookup') ||
        errorStr.contains('nodename') ||
        errorStr.contains('servname')) {
      return noInternetConnection;
    }

    // Network unreachable
    if (errorStr.contains('network is unreachable') ||
        errorStr.contains('no internet')) {
      return networkUnreachable;
    }

    // Timeout errors
    if (errorStr.contains('timeout') || errorStr.contains('timed out')) {
      return connectionTimeout;
    }

    // Socket errors
    if (errorStr.contains('socket') ||
        errorStr.contains('broken pipe') ||
        errorStr.contains('connection reset')) {
      return connectionInterrupted;
    }

    // SSL errors
    if (errorStr.contains('ssl') ||
        errorStr.contains('certificate') ||
        errorStr.contains('handshake')) {
      return sslError;
    }

    // Server errors
    if (errorStr.contains('500') || errorStr.contains('internal server error')) {
      return internalServerError;
    }

    if (errorStr.contains('502') || errorStr.contains('bad gateway')) {
      return badGateway;
    }

    if (errorStr.contains('503') || errorStr.contains('service unavailable')) {
      return serviceUnavailable;
    }

    if (errorStr.contains('504') || errorStr.contains('gateway timeout')) {
      return gatewayTimeout;
    }

    // Auth errors
    if (errorStr.contains('401') ||
        errorStr.contains('unauthorized') ||
        errorStr.contains('invalid token')) {
      return sessionExpired;
    }

    if (errorStr.contains('403') || errorStr.contains('forbidden')) {
      return forbidden;
    }

    if (errorStr.contains('404') || errorStr.contains('not found')) {
      return notFound;
    }

    // Default fallback
    return genericNetworkError;
  }

  /// Get title for error type
  static String getTitle(String message) {
    final msgLower = message.toLowerCase();

    if (msgLower.contains('internet') || msgLower.contains('koneksi')) {
      return 'Masalah Koneksi';
    }
    if (msgLower.contains('server')) {
      return 'Server Error';
    }
    if (msgLower.contains('sesi') || msgLower.contains('login')) {
      return 'Sesi Berakhir';
    }
    if (msgLower.contains('izin') || msgLower.contains('forbidden')) {
      return 'Akses Ditolak';
    }

    return 'Terjadi Kesalahan';
  }
}
