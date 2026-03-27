import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  GoTrueClient get _auth => Supabase.instance.client.auth;
  static const String _authKey = 'is_authenticated';

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

  // ── Phone OTP authentication (Supabase native) ───────────
  /// Sends an OTP to [phoneNumber] via Supabase Auth (POST /auth/v1/token).
  Future<void> sendPhoneOtp({required String phoneNumber}) async {
    await _auth.signInWithOtp(phone: phoneNumber);
  }

  /// Verifies the OTP received on [phoneNumber].
  Future<String?> verifyPhoneOtp({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final AuthResponse res = await _auth.verifyOTP(
        type: OtpType.sms,
        phone: phoneNumber,
        token: otp,
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

  // Legacy helpers kept for backward compatibility
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(dynamic) onVerified,
    required void Function(Exception) onFailed,
    required void Function(String, int?) onCodeSent,
  }) async {
    try {
      await sendPhoneOtp(phoneNumber: phoneNumber);
      onCodeSent(phoneNumber, null);
    } catch (e) {
      onFailed(Exception(e.toString()));
    }
  }

  Future<String?> signInWithPhoneCredential(dynamic credential) async {
    // credential is expected to be a Map with 'phone' and 'otp' keys,
    // or a plain OTP string (legacy behavior).
    if (credential is Map) {
      return verifyPhoneOtp(
        phoneNumber: credential['phone'] as String,
        otp: credential['otp'] as String,
      );
    }
    throw 'signInWithPhoneCredential requires a Map with phone and otp keys';
  }
}
