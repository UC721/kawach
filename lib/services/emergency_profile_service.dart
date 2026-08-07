import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/emergency_profile_model.dart';
import '../utils/constants.dart';

/// Medically + legally actionable profile shared with responders during an SOS.
/// Syncs to Supabase and mirrors locally for offline read access.
class EmergencyProfileService extends ChangeNotifier {
  static const String _cacheKey = 'kawach.emergency_profile.v1';

  final SupabaseClient _db = Supabase.instance.client;

  EmergencyProfileModel _profile = const EmergencyProfileModel();
  bool _loading = false;
  bool _isSetupComplete = false;

  EmergencyProfileModel get profile => _profile;
  bool get loading => _loading;
  bool get isSetupComplete => _isSetupComplete;

  Future<void> load(String userId) async {
    _loading = true;
    notifyListeners();

    final local = await _readLocal();
    if (local != null) {
      _profile = local;
      _isSetupComplete = !local.isEmpty;
    }

    try {
      final response = await _db
          .from(FSCollection.emergencyProfiles)
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (response != null) {
        final profile =
            EmergencyProfileModel.fromMap(response['profile'] ?? response);
        _profile = profile;
        _isSetupComplete = !profile.isEmpty;
        await _writeLocal(profile);
      }
    } catch (_) {}

    _loading = false;
    notifyListeners();
  }

  Future<void> save(String userId, EmergencyProfileModel profile) async {
    _profile = profile;
    _isSetupComplete = !profile.isEmpty;
    notifyListeners();

    await _tabulate(userId);
    await _writeLocal(profile);

    try {
      final payload = {
        'user_id': userId,
        'profile': jsonEncode(profile.toMap()),
        'updated_at': DateTime.now().toIso8601String(),
      };
      await _db.from(FSCollection.emergencyProfiles).upsert(payload);
    } catch (_) {
      await _enqueueOffline(userId, profile);
    }
  }

  Stream<EmergencyProfileModel?> stream(String userId) {
    return _db
        .from(FSCollection.emergencyProfiles)
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((docs) {
          if (docs.isEmpty) {
            return null;
          }
          final row = docs.first;
          final data = row['profile'];
          if (data is String) {
            return EmergencyProfileModel.fromMap(
              jsonDecode(data) as Map<String, dynamic>,
            );
          }
          return EmergencyProfileModel.fromMap(row);
        });
  }

  /// Keeps a lightweight, always-available copy on this device even offline.
  Future<void> _writeLocal(EmergencyProfileModel profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, jsonEncode(profile.toMap()));
  }

  Future<EmergencyProfileModel?> _readLocal() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) {
      return null;
    }
    try {
      return EmergencyProfileModel.fromMap(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _tabulate(String userId) async {
    try {
      // Tell the activity log the profile was refreshed (best-effort).
      await _db.from(FSCollection.activityLogs).insert({
        'user_id': userId,
        'event': 'Emergency profile updated',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> _enqueueOffline(
      String userId, EmergencyProfileModel profile) async {
    // Persist intent for the offline sync pipeline (Module 6) to reconcile.
    final prefs = await SharedPreferences.getInstance();
    final pending = prefs.getStringList('kawach.offline.profile_updates') ??
        const <String>[];
    pending.add(jsonEncode(
        {'user_id': userId, 'profile': jsonEncode(profile.toMap())}));
    await prefs.setStringList('kawach.offline.profile_updates', pending);
  }
}
