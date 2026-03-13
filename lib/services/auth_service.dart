import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final GoTrueClient _auth = Supabase.instance.client.auth;
  static const String _authKey = 'is_authenticated';

  bool _isAuthenticated = false;

  AuthService() {
    _loadAuthState();
    _auth.onAuthStateChange.listen((data) {
      if (data.session != null) {
        _setAuthState(true);
      } else {
        _setAuthState(false);
      }
    });
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

  // Simplified phone auth for demo
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required void Function(dynamic) onVerified,
    required void Function(Exception) onFailed,
    required void Function(String, int?) onCodeSent,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    onCodeSent('mock_verification_id', null);
  }

  Future<String?> signInWithPhoneCredential(dynamic credential) async {
    try {
      final AuthResponse res = await _auth.verifyOTP(
        type: OtpType.sms,
        token: credential.toString(),
        phone: 'phone_number_from_elsewhere', // Simplified for demo, needs proper handling
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
}
