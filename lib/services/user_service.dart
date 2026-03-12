import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_model.dart';
import '../models/guardian_model.dart';
import '../utils/constants.dart';

class UserService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _userKey = 'current_user_data';

  UserModel? _currentUserModel;
  UserModel? get currentUserModel => _currentUserModel;

  // ── Mock in-memory database ────────────────────────────────
  final Map<String, UserModel> _mockDb = {};

  // ── Load current user profile ────────────────────────────────
  Future<void> loadCurrentUser(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userKey);
    
    if (userData != null) {
      try {
        final Map<String, dynamic> map = jsonDecode(userData);
        // Note: Firestore Timestamp doesn't decode from JSON directly, 
        // using a simple mock approach for the demo.
        _currentUserModel = UserModel(
          userId: map['userId'] ?? uid,
          name: map['name'] ?? 'User',
          phone: map['phone'] ?? '',
          email: map['email'],
          guardianIds: List<String>.from(map['guardianIds'] ?? []),
          createdAt: DateTime.now(),
        );
        _mockDb[uid] = _currentUserModel!;
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('Error decoding persisted user: $e');
      }
    }

    // Fallback to mock delay
    await Future.delayed(const Duration(milliseconds: 500));
    if (_mockDb.containsKey(uid)) {
      _currentUserModel = _mockDb[uid];
      notifyListeners();
    }
  }

  // ── Create user profile ──────────────────────────────────────
  Future<void> createUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    final userData = jsonEncode({
      'userId': user.userId,
      'name': user.name,
      'phone': user.phone,
      'email': user.email,
      'guardianIds': user.guardianIds,
    });
    await prefs.setString(_userKey, userData);
    
    _mockDb[user.userId] = user;
    _currentUserModel = user;
    notifyListeners();
  }

  // ── Update user profile ──────────────────────────────────────
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    if (_currentUserModel != null) {
      _currentUserModel = _currentUserModel!.copyWith(
        name: data['name'] ?? _currentUserModel!.name,
        phone: data['phone'] ?? _currentUserModel!.phone,
      );
      await createUser(_currentUserModel!);
    }
  }

  // ── Guardians ────────────────────────────────────────────────
  Future<List<GuardianModel>> getGuardians(String userId) async {
    // For demo, return empty list if not connected to real Firestore
    try {
      final snap = await _db
          .collection(FSCollection.guardians)
          .where('userId', isEqualTo: userId)
          .get();
      return snap.docs.map((d) => GuardianModel.fromFirestore(d)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> addGuardian(GuardianModel guardian) async {
    final ref = _db.collection(FSCollection.guardians).doc();
    await ref.set(guardian.toMap());

    final uid = guardian.userId;
    await _db.collection(FSCollection.users).doc(uid).update({
      'guardians': FieldValue.arrayUnion([ref.id]),
    });
    await loadCurrentUser(uid);
  }

  Future<void> removeGuardian(String userId, String guardianId) async {
    await _db.collection(FSCollection.guardians).doc(guardianId).delete();
    await _db.collection(FSCollection.users).doc(userId).update({
      'guardians': FieldValue.arrayRemove([guardianId]),
    });
    await loadCurrentUser(userId);
  }

  Future<void> logActivity(String userId, String event) async {
    debugPrint('User Activity: $event by User $userId');
  }

  Stream<UserModel?> streamUser(String uid) async* {
    while (true) {
      await Future.delayed(const Duration(seconds: 2));
      yield _currentUserModel;
    }
  }
}
