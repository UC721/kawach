import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _authKey = 'is_authenticated';

  bool _isAuthenticated = false;

  AuthService() {
    _loadAuthState();
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

  String? get currentUserId => _isAuthenticated ? 'mock_user_123' : null;
  
  Stream<dynamic> get authStateChanges async* { yield null; } 
  bool get isAuthenticated => _isAuthenticated;

  Future<String?> signInWithEmail(String email, String password) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      if (email.isEmpty || password.isEmpty) {
         throw Exception('Email and password cannot be empty.');
      }
      await _setAuthState(true);
      return 'mock_user_123'; 
    } catch (e) {
      throw e.toString();
    }
  }

  Future<String?> signUpWithEmail(String email, String password) async {
    try {
      await Future.delayed(const Duration(seconds: 1));
      if (email.isEmpty || password.length < 6) {
         throw Exception('Please enter a valid email and a password with at least 6 characters.');
      }
      await _setAuthState(true);
      return 'mock_user_123';
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
      await Future.delayed(const Duration(seconds: 1));
      await _setAuthState(true);
      return 'mock_user_123';
    } catch (e) {
      throw e.toString();
    }
  }
}
