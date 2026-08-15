import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/safe_walk_session_model.dart';
import '../utils/constants.dart';

class SafeWalkSessionService extends ChangeNotifier {
  final SupabaseClient _db = Supabase.instance.client;
  final _uuid = const Uuid();

  SafeWalkSessionModel? _activeSession;
  SafeWalkSessionModel? get activeSession => _activeSession;

  /// Start a new safe-walk session.
  Future<SafeWalkSessionModel> startSession({
    required String userId,
    String? guardianId,
    double? startLat,
    double? startLng,
    double? destLat,
    double? destLng,
    int durationSeconds = AppThresholds.safeWalkDefaultSeconds,
  }) async {
    final session = SafeWalkSessionModel(
      id: _uuid.v4(),
      userId: userId,
      guardianId: guardianId,
      status: 'active',
      startLat: startLat,
      startLng: startLng,
      destLat: destLat,
      destLng: destLng,
      durationSeconds: durationSeconds,
      startedAt: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await _db
        .from(FSCollection.safeWalkSessions)
        .insert(session.toMap());

    _activeSession = session;
    notifyListeners();
    return session;
  }

  /// Mark the session as completed (user arrived safely).
  Future<void> confirmArrival(String sessionId) async {
    await _db.from(FSCollection.safeWalkSessions).update({
      'status': 'completed',
      'endedAt': DateTime.now().toIso8601String(),
    }).eq('id', sessionId);

    _activeSession = null;
    notifyListeners();
  }

  /// Mark the session as expired (timer ran out).
  Future<void> expireSession(String sessionId) async {
    await _db.from(FSCollection.safeWalkSessions).update({
      'status': 'expired',
      'endedAt': DateTime.now().toIso8601String(),
    }).eq('id', sessionId);

    _activeSession = null;
    notifyListeners();
  }

  /// Mark the session as emergency triggered.
  Future<void> triggerEmergency(String sessionId) async {
    await _db.from(FSCollection.safeWalkSessions).update({
      'status': 'emergency_triggered',
      'endedAt': DateTime.now().toIso8601String(),
    }).eq('id', sessionId);

    _activeSession = null;
    notifyListeners();
  }

  /// Get session history for a user.
  Future<List<SafeWalkSessionModel>> getSessionHistory(
      String userId) async {
    final res = await _db
        .from(FSCollection.safeWalkSessions)
        .select()
        .eq('userId', userId)
        .order('createdAt', ascending: false);
    return (res as List)
        .map((d) => SafeWalkSessionModel.fromMap(d))
        .toList();
  }

  /// Stream the active session for a user.
  Stream<SafeWalkSessionModel?> streamActiveSession(String userId) {
    return _db
        .from(FSCollection.safeWalkSessions)
        .stream(primaryKey: ['id'])
        .eq('userId', userId)
        .map((docs) {
      final active =
          docs.where((d) => d['status'] == 'active').toList();
      if (active.isEmpty) return null;
      return SafeWalkSessionModel.fromMap(active.first);
    });
  }
}
