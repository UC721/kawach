import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/guardian_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class UserService extends ChangeNotifier {
  final SupabaseClient _db = Supabase.instance.client;
  static const String _userKey = 'current_user_data';

  UserModel? _currentUserModel;
  UserModel? get currentUserModel => _currentUserModel;

  Future<void> loadCurrentUser(String uid) async {
    final prefs = await SharedPreferences.getInstance();

    try {
      final response = await _db
          .from(FSCollection.users)
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      if (response != null) {
        _currentUserModel = UserModel.fromMap(response);
        await prefs.setString(_userKey, jsonEncode(response));
        notifyListeners();
        return;
      }
    } catch (_) {}

    final local = prefs.getString(_userKey);
    if (local != null) {
      _currentUserModel = UserModel.fromMap(
        jsonDecode(local) as Map<String, dynamic>,
      );
      notifyListeners();
    }
  }

  Future<void> createUser(UserModel user) async {
    final payload = {
      'user_id': user.userId,
      ...user.toMap(),
    };
    final prefs = await SharedPreferences.getInstance();

    try {
      await _db.from(FSCollection.users).upsert(payload);
    } finally {
      await prefs.setString(_userKey, jsonEncode(payload));
      _currentUserModel = user;
      notifyListeners();
    }
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    final payload = <String, dynamic>{
      if (data['name'] != null) 'name': data['name'],
      if (data['phone'] != null) 'phone': data['phone'],
      if (data['email'] != null) 'email': data['email'],
    };
    await _db.from(FSCollection.users).update(payload).eq('user_id', uid);
    await loadCurrentUser(uid);
  }

  Future<List<GuardianModel>> getGuardians(String userId) async {
    try {
      final response = await _db
          .from(FSCollection.guardians)
          .select()
          .eq('user_id', userId);
      return (response as List)
          .map((item) => GuardianModel.fromMap(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> addGuardian(GuardianModel guardian) async {
    await _db.from(FSCollection.guardians).upsert(guardian.toMap());
    await loadCurrentUser(guardian.userId);
  }

  Future<void> removeGuardian(String userId, String guardianId) async {
    await _db
        .from(FSCollection.guardians)
        .delete()
        .eq('guardian_id', guardianId);
    await loadCurrentUser(userId);
  }

  Future<void> logActivity(String userId, String event) async {
    await _db.from(FSCollection.activityLogs).insert({
      'user_id': userId,
      'event': event,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Stream<UserModel?> streamUser(String uid) {
    return _db
        .from(FSCollection.users)
        .stream(primaryKey: ['user_id'])
        .eq('user_id', uid)
        .map((docs) => docs.isEmpty ? null : UserModel.fromMap(docs.first));
  }
}
