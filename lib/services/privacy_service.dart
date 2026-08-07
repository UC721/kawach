import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart';

class DataExport {
  final String json;
  final Map<String, int> counts;
  const DataExport({required this.json, required this.counts});
}

/// Admin-level control over the user's own data: full export, local encryption
/// key rotation and complete erasure. Erasure follows a best-effort sweep of
/// every collection that holds a `user_id` for the account.
class PrivacyService extends ChangeNotifier {
  static const String _localKey = 'kawach.local.encryption_key';

  final SupabaseClient _db = Supabase.instance.client;

  String? _cachedFingerprint;
  String? get localKeyFingerprint => _cachedFingerprint;

  bool _exporting = false;
  bool _erasing = false;
  bool get exporting => _exporting;
  bool get erasing => _erasing;

  Future<void> ensureLocalKey() async {
    if (_cachedFingerprint != null) {
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    var key = prefs.getString(_localKey);
    if (key == null || key.isEmpty) {
      key = _generateKey();
      await prefs.setString(_localKey, key);
    }
    _cachedFingerprint = _fingerprint(key);
    notifyListeners();
  }

  Future<String> rotateLocalKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = _generateKey();
    await prefs.setString(_localKey, key);
    _cachedFingerprint = _fingerprint(key);
    notifyListeners();
    return _cachedFingerprint!;
  }

  Future<DataExport> exportData(String userId) async {
    _exporting = true;
    notifyListeners();

    final data = <String, dynamic>{};
    final counts = <String, int>{};

    try {
      final user = await _db
          .from(FSCollection.users)
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      data['user'] = user;
    } catch (_) {}

    await _exportSection(
      userId,
      FSCollection.guardians,
      data,
      counts,
      key: 'guardians',
    );
    await _exportSection(
      userId,
      FSCollection.emergencies,
      data,
      counts,
      key: 'emergencies',
    );
    await _exportSection(
      userId,
      FSCollection.evidenceVault,
      data,
      counts,
      key: 'evidence',
    );
    await _exportSection(
      userId,
      FSCollection.reports,
      data,
      counts,
      key: 'reports',
    );
    await _exportSection(
      userId,
      FSCollection.locations,
      data,
      counts,
      key: 'location_updates',
    );
    await _exportSection(
      userId,
      FSCollection.activityLogs,
      data,
      counts,
      key: 'activity_logs',
    );

    final profile = await _loadProfile(userId);
    if (profile != null) {
      data['emergency_profile'] = profile;
      counts['emergency_profile'] = 1;
    }

    data['exported_at'] = DateTime.now().toIso8601String();
    data['user_id'] = userId;

    _exporting = false;
    notifyListeners();
    return DataExport(
        json: const JsonEncoder.withIndent('  ').convert(data), counts: counts);
  }

  Future<void> eraseAllData(String userId) async {
    _erasing = true;
    notifyListeners();

    for (final table in [
      FSCollection.guardians,
      FSCollection.emergencies,
      FSCollection.evidenceVault,
      FSCollection.reports,
      FSCollection.locations,
      FSCollection.activityLogs,
      FSCollection.emergencyProfiles,
      FSCollection.guardianRequests,
      FSCollection.sosAcknowledgements,
    ]) {
      try {
        await _db.from(table).delete().eq('user_id', userId);
      } catch (_) {}
    }

    // Local-only sweep: queues, caches and the key itself.
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('kawach.'));
    for (final key in keys) {
      await prefs.remove(key);
    }

    _erasing = false;
    notifyListeners();
  }

  Future<Map<String, dynamic>?> _loadProfile(String userId) async {
    try {
      final row = await _db
          .from(FSCollection.emergencyProfiles)
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) {
        return null;
      }
      final raw = row['profile'];
      if (raw is String) {
        return jsonDecode(raw) as Map<String, dynamic>;
      }
      return raw as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<void> _exportSection(
    String userId,
    String table,
    Map<String, dynamic> data,
    Map<String, int> counts, {
    required String key,
  }) async {
    try {
      final response = await _db.from(table).select().eq('user_id', userId);
      final rows = (response as List).toList();
      data[key] = rows;
      counts[key] = rows.length;
    } catch (_) {
      data[key] = [];
      counts[key] = 0;
    }
  }

  String _generateKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  String _fingerprint(String key) {
    final digest = sha256.convert(utf8.encode(key));
    return digest.toString().substring(0, 16).toUpperCase();
  }
}
