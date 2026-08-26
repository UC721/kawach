import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  GoTrueClient get _auth => Supabase.instance.client.auth;
  static const String _authKey = 'is_authenticated';

  /// JWT expiry duration (15 minutes) configured in Supabase project settings.
  static const Duration jwtExpiry = Duration(minutes: 15);

  bool _isAuthenticated = false;

  AuthService() {
    _loadAuthState();
    _initAuthListener();
  }

  void _initAuthListener() {
    try {
      _auth.onAuthStateChange.listen((data) {
        if (data.session != null) {
          _setAuthState(true);
        } else {
          _setAuthState(false);
        }
      });
    } catch (e) {
      debugPrint('AuthService: Failed to init auth listener (Supabase might not be ready): $e');
    }
  }

  Future<void> _loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    _isAuthenticated = prefs.getBool(_authKey) ?? false;
    notifyListeners();
  }

  Future<void> _setAuthState(bool state) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_authKey, state);
    _isAuthenticated = state;
    notifyListeners();
  }

  String? get currentUserId => _auth.currentUser?.id;
  
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange; 
  bool get isAuthenticated => _isAuthenticated;

  Future<String?> signInWithEmail(String email, String password) async {
    try {
      final AuthResponse res = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (res.user != null) {
        await _setAuthState(true);
        return res.user?.id; 
      }
      return null;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<String?> signUpWithEmail(String email, String password) async {
    try {
      final AuthResponse res = await _auth.signUp(
        email: email,
        password: password,
      );
      if (res.user != null) {
        await _setAuthState(true);
        return res.user?.id;
      }
      return null;
    } catch (e) {
      throw e.toString();
    }
  }

  Future<void> signOut() async {
    await _setAuthState(false);
    await _auth.signOut();
  }

  // ── Phone OTP authentication ──────────────────────────────────

  /// Sends a one-time password to [phoneNumber] via Supabase Auth (SMS OTP).
  Future<void> sendPhoneOtp({required String phoneNumber}) async {
    await _auth.signInWithOtp(phone: phoneNumber);
  }

  /// Verifies the SMS OTP and signs in the user.
  ///
  /// Returns the user ID on success, or `null` on failure.
  /// The resulting JWT has a 15-minute expiry (configured server-side).
  Future<String?> verifyPhoneOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final AuthResponse res = await _auth.verifyOTP(
        type: OtpType.sms,
        token: otp,
        phone: phoneNumber,
      );
      if (res.user != null) {
        await _setAuthState(true);
        return res.user?.id;
      }
      return null;
    } catch (e) {
      throw e.toString();
    }
  }

  /// Returns true if the current session token is still valid.
  bool get isSessionValid {
    final session = _auth.currentSession;
    if (session == null) return false;
    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      (session.expiresAt ?? 0) * 1000,
    );
    return DateTime.now().isBefore(expiresAt);
  }

  /// Refreshes the session token if it has expired.
  Future<void> refreshSessionIfNeeded() async {
    if (!isSessionValid) {
      await _auth.refreshSession();
    }
  }
}
