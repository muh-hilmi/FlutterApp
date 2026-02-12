import 'package:google_sign_in/google_sign_in.dart';
import '../utils/app_logger.dart';

class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
      'profile',
    ],
    // Web Client ID from GCP OAuth credentials - used for backend authentication
    serverClientId: '159931249039-js9bnrj9tggukd5a4o7h0aeapkq3u7rm.apps.googleusercontent.com',
  );

  final _logger = AppLogger();

  /// Sign in with Google
  Future<GoogleSignInAccount?> signIn() async {
    try {
      final account = await _googleSignIn.signIn();

      if (account != null) {
        _logger.info('Google sign-in successful: ${account.email}');
      }
      return account;
    } catch (error) {
      _logger.error('Google sign-in failed', error);
      rethrow;
    }
  }

  /// Sign out from Google
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
      _logger.info('Google sign-out successful');
    } catch (error) {
      _logger.error('Google sign-out failed', error);
      rethrow;
    }
  }

  /// Disconnect from Google (revoke access)
  Future<void> disconnect() async {
    try {
      await _googleSignIn.disconnect();
    } catch (error) {
      _logger.error('Google disconnect failed', error);
      rethrow;
    }
  }

  /// Get currently signed in account
  GoogleSignInAccount? get currentUser => _googleSignIn.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _googleSignIn.currentUser != null;

  /// Get authentication token
  Future<String?> getIdToken() async {
    try {
      final account = _googleSignIn.currentUser;
      if (account == null) return null;

      final auth = await account.authentication;
      return auth.idToken;
    } catch (error) {
      _logger.error('Failed to get Google ID token', error);
      return null;
    }
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    try {
      final account = _googleSignIn.currentUser;
      if (account == null) return null;

      final auth = await account.authentication;
      return auth.accessToken;
    } catch (error) {
      _logger.error('Failed to get Google access token', error);
      return null;
    }
  }

  /// Sign in silently (automatic sign-in if previously signed in)
  Future<GoogleSignInAccount?> signInSilently() async {
    try {
      final account = await _googleSignIn.signInSilently();

      if (account != null) {
        _logger.info('Silent sign-in successful: ${account.email}');
      }
      return account;
    } catch (error) {
      _logger.debug('Silent sign-in failed', error);
      return null;
    }
  }
}
