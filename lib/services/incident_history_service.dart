import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/emergency_model.dart';
import '../models/evidence_model.dart';
import '../models/incident_event_model.dart';
import '../models/sos_acknowledgement_model.dart';
import '../utils/constants.dart';

/// Merges SOS events, evidence captures, guardian acknowledgements and activity
/// logs into one chronological incident timeline. Reads optimistically from a
/// local cache so history is always available, then reconciles with the server.
class IncidentHistoryService extends ChangeNotifier {
  static const String _cacheKey = 'kawach.incidents.cache.v1';

  final SupabaseClient _db = Supabase.instance.client;

  List<IncidentEventModel> _events = [];
  bool _loading = false;

  List<IncidentEventModel> get events => _events;
  bool get loading => _loading;

  Future<List<IncidentEventModel>> buildTimeline(String userId,
      {bool refresh = true}) async {
    if (refresh) {
      _loading = true;
      notifyListeners();
      await _loadAndCache(userId);
    } else {
      await _restoreCache(userId);
    }
    return _events;
  }

  Future<void> _loadAndCache(String userId) async {
    var precedent = _events;
    try {
      final emergencies = await _fetchEmergencies(userId);
      final evidence = await _fetchEvidence(userId);
      final acks = await _fetchAcks(userId);
      final activity = await _fetchActivity(userId);
      precedent = _merge(emergencies, evidence, acks, activity);
      await _writeCache(precedent);
    } catch (_) {
      final cached = await _readCache();
      if (cached != null) {
        precedent = cached;
      }
    }
    _events = precedent;
    _loading = false;
    notifyListeners();
  }

  Future<void> _restoreCache(String userId) async {
    final cached = await _readCache();
    if (cached != null) {
      _events = cached;
      notifyListeners();
    }
  }

  List<IncidentEventModel> _merge(
    List<EmergencyModel> emergencies,
    List<EvidenceModel> evidence,
    List<SosAcknowledgementModel> acks,
    List<Map<String, dynamic>> activity,
  ) {
    final events = <IncidentEventModel>[];

    for (final emergency in emergencies) {
      events.add(IncidentEventModel(
        id: 'e-${emergency.emergencyId}',
        kind: IncidentKind.emergency,
        timestamp: emergency.createdAt,
        title: 'SOS triggered (${emergency.triggeredBy.name})',
        detail:
            'Emergency ${emergency.emergencyId.substring(0, 8)} · ${emergency.status.name}',
        emergencyId: emergency.emergencyId,
      ));
      if (emergency.resolvedAt != null) {
        events.add(IncidentEventModel(
          id: 'r-${emergency.emergencyId}',
          kind: IncidentKind.resolved,
          timestamp: emergency.resolvedAt!,
          title: 'SOS resolved',
          detail: 'KAWACH marked this emergency as resolved.',
          emergencyId: emergency.emergencyId,
        ));
      }
    }

    for (final item in evidence) {
      final isAudio = item.audioUrl != null;
      events.add(IncidentEventModel(
        id: 'v-${item.evidenceId}',
        kind: IncidentKind.evidence,
        timestamp: item.timestamp,
        title: isAudio ? 'Audio evidence captured' : 'Video/photo evidence',
        detail: 'Evidence recorded during the incident',
        emergencyId: item.emergencyId,
      ));
    }

    for (final ack in acks) {
      events.add(IncidentEventModel(
        id: 'a-${ack.ackId}',
        kind: IncidentKind.acknowledgement,
        timestamp: ack.createdAt,
        title: '${ack.guardianName} replied',
        detail: ack.status == SosAckStatus.confirmedSafe
            ? 'Confirmed you are safe.'
            : 'Said they are checking on you.',
        emergencyId: ack.emergencyId,
      ));
    }

    for (final row in activity) {
      final timestamp = DateTime.tryParse(row['created_at'] ?? '');
      if (timestamp == null) continue;
      events.add(IncidentEventModel(
        id: 'l-${row['activity_id'] ?? timestamp.microsecondsSinceEpoch}',
        kind: IncidentKind.activity,
        timestamp: timestamp,
        title: row['event'] ?? 'Activity',
        detail: '',
      ));
    }

    events.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return events;
  }

  Future<List<EmergencyModel>> _fetchEmergencies(String userId) async {
    final response = await _db
        .from(FSCollection.emergencies)
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: true);
    return (response as List)
        .map((row) => EmergencyModel.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<EvidenceModel>> _fetchEvidence(String userId) async {
    final response = await _db
        .from(FSCollection.evidenceVault)
        .select()
        .eq('user_id', userId)
        .order('timestamp', ascending: true);
    return (response as List)
        .map((row) => EvidenceModel.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<SosAcknowledgementModel>> _fetchAcks(String userId) async {
    try {
      final response = await _db
          .from(FSCollection.sosAcknowledgements)
          .select()
          .eq('emergency_user_id', userId);
      return (response as List)
          .map((row) =>
              SosAcknowledgementModel.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<List<Map<String, dynamic>>> _fetchActivity(String userId) async {
    try {
      final response = await _db
          .from(FSCollection.activityLogs)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: true);
      return (response as List)
          .map((row) => row as Map<String, dynamic>)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _writeCache(List<IncidentEventModel> events) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _cacheKey,
      jsonEncode(events.map((e) => _eventToMap(e)).toList()),
    );
  }

  Future<List<IncidentEventModel>?> _readCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_cacheKey);
    if (raw == null) {
      return null;
    }
    try {
      final list = jsonDecode(raw) as List;
      return list.map((e) => _eventFromMap(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _eventToMap(IncidentEventModel e) => {
        'id': e.id,
        'kind': e.kind.name,
        'timestamp': e.timestamp.toIso8601String(),
        'title': e.title,
        'detail': e.detail,
        'emergencyId': e.emergencyId,
      };

  IncidentEventModel _eventFromMap(Map<String, dynamic> map) =>
      IncidentEventModel(
        id: map['id'] ?? '',
        kind: IncidentKind.values.firstWhere(
          (k) => k.name == map['kind'],
          orElse: () => IncidentKind.activity,
        ),
        timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
        title: map['title'] ?? '',
        detail: map['detail'] ?? '',
        emergencyId: map['emergencyId'],
      );
}
