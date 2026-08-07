import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/emergency_model.dart';
import '../models/guardian_request_model.dart';
import '../models/sos_acknowledgement_model.dart';
import '../utils/constants.dart';

/// Owns the two-way guardian lifecycle: how a person becomes a guardian AND how
/// a guardian replies to a live SOS it was alerted to, closing the feedback
/// loop. Offline intent is cached locally and reconciled on reconnection.
class GuardianLifecycleService extends ChangeNotifier {
  static const String _offlineRequestsKey = 'kawach.offline.guardian_requests';
  static const String _offlineAcksKey = 'kawach.offline.sos_acks';

  final SupabaseClient _db = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  List<GuardianRequestModel> _outgoingRequests = [];
  List<GuardianRequestModel> get outgoingRequests => _outgoingRequests;

  final List<SosAcknowledgementModel> _responses = [];
  List<SosAcknowledgementModel> get responses => _responses;

  final StreamController<List<GuardianRequestModel>> _incomingController =
      StreamController<List<GuardianRequestModel>>.broadcast();
  final StreamController<List<EmergencyModel>> _guardingController =
      StreamController<List<EmergencyModel>>.broadcast();
  final StreamController<List<SosAcknowledgementModel>> _acksController =
      StreamController<List<SosAcknowledgementModel>>.broadcast();

  Stream<List<GuardianRequestModel>> get incomingRequests =>
      _incomingController.stream;
  Stream<List<EmergencyModel>> get guardingEmergencies =>
      _guardingController.stream;
  Stream<List<SosAcknowledgementModel>> get acknowledgements =>
      _acksController.stream;

  Future<String> sendGuardianRequest({
    required String initiatorUserId,
    required String initiatorName,
    required String initiatorPhone,
    required String guardianUserId,
  }) async {
    final request = GuardianRequestModel(
      requestId: _uuid.v4(),
      initiatorUserId: initiatorUserId,
      initiatorName: initiatorName,
      initiatorPhone: initiatorPhone,
      guardianUserId: guardianUserId,
      status: GuardianRequestStatus.pending,
      createdAt: DateTime.now(),
    );

    try {
      await _db.from(FSCollection.guardianRequests).insert(request.toMap());
    } catch (_) {
      await _encodeOffline(request);
    }
    _outgoingRequests.insert(0, request);
    notifyListeners();
    return request.requestId;
  }

  Future<void> respondToRequest({
    required GuardianRequestModel request,
    required bool accept,
  }) async {
    final status = accept
        ? GuardianRequestStatus.accepted
        : GuardianRequestStatus.declined;
    final now = DateTime.now();

    try {
      await _db.from(FSCollection.guardianRequests).update({
        'status': status.name,
        'responded_at': now.toIso8601String()
      }).eq('request_id', request.requestId);

      if (accept) {
        // Registration so both sides can receive each other's SOS alerts.
        await _db.from(FSCollection.guardians).upsert({
          'guardian_id': request.guardianUserId,
          'user_id': request.initiatorUserId,
          'name': request.initiatorName,
          'phone': request.initiatorPhone,
          'relationship': 'Guardian',
        });
      }
    } catch (_) {
      if (accept) {
        await _encodeOffline(
          GuardianRequestModel(
            requestId: request.requestId,
            initiatorUserId: request.initiatorUserId,
            initiatorName: request.initiatorName,
            initiatorPhone: request.initiatorPhone,
            guardianUserId: request.guardianUserId,
            status: status,
            createdAt: request.createdAt,
            respondedAt: now,
          ),
        );
      }
    }
    // Notify listeners to repaint the pending list.
    notifyListeners();
  }

  Future<void> acknowledgeSos({
    required String emergencyId,
    required String emergencyUserId,
    required String guardianUserId,
    required String guardianName,
    required SosAckStatus status,
  }) async {
    final ack = SosAcknowledgementModel(
      ackId: _uuid.v4(),
      emergencyId: emergencyId,
      emergencyUserId: emergencyUserId,
      guardianUserId: guardianUserId,
      guardianName: guardianName,
      status: status,
      createdAt: DateTime.now(),
    );

    try {
      await _db.from(FSCollection.sosAcknowledgements).upsert(
            ack.toMap(),
            onConflict: 'ack_id',
          );
    } catch (_) {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(_offlineAcksKey) ?? const <String>[];
      list.add(jsonEncode(ack.toMap()));
      await prefs.setStringList(_offlineAcksKey, list);
    }
    _responses.insert(0, ack);
    notifyListeners();
  }

  Future<List<GuardianRequestModel>> fetchOutgoing(
      String initiatorUserId) async {
    try {
      final response = await _db
          .from(FSCollection.guardianRequests)
          .select()
          .eq('initiator_user_id', initiatorUserId);
      _outgoingRequests = (response as List)
          .map((row) =>
              GuardianRequestModel.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      await _restoreOfflineRequests();
    }
    notifyListeners();
    return _outgoingRequests;
  }

  void listenIncoming(String guardianUserId) {
    final stream = _db
        .from(FSCollection.guardianRequests)
        .stream(primaryKey: ['request_id'])
        .eq('guardian_user_id', guardianUserId)
        .map((docs) => docs
            .map(GuardianRequestModel.fromMap)
            .where((r) => r.status == GuardianRequestStatus.pending)
            .toList());
    _incomingController.addStream(stream, cancelOnError: true);
  }

  void listenGuardingEmergencies(String guardianUserId) {
    streamOfGuardingEmergencies(guardianUserId)
        .then((list) => _guardingController.add(list));
  }

  Future<List<EmergencyModel>> streamOfGuardingEmergencies(
    String guardianUserId,
  ) async {
    try {
      final guardianRows = await _db
          .from(FSCollection.guardians)
          .select()
          .eq('guardian_id', guardianUserId);
      final guardedUserIds = (guardianRows as List)
          .map((row) => (row['user_id'] ?? '') as String)
          .where((id) => id.isNotEmpty)
          .toSet();
      if (guardedUserIds.isEmpty) {
        return const [];
      }
      final response = await _db
          .from(FSCollection.emergencies)
          .select()
          .inFilter('user_id', guardedUserIds.toList())
          .order('created_at', ascending: false);
      return (response as List)
          .map((row) => EmergencyModel.fromMap(row as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  void listenAcksForEmergency(String emergencyId) {
    final stream = _db
        .from(FSCollection.sosAcknowledgements)
        .stream(primaryKey: ['ack_id'])
        .eq('emergency_id', emergencyId)
        .map((docs) => docs.map(SosAcknowledgementModel.fromMap).toList());
    _acksController.addStream(stream, cancelOnError: true);
  }

  Future<void> flushOfflineAcks() async {
    final prefs = await SharedPreferences.getInstance();
    final rawList = prefs.getStringList(_offlineAcksKey);
    if (rawList == null || rawList.isEmpty) {
      return;
    }
    final failed = <String>[];
    for (final raw in rawList) {
      try {
        await _db
            .from(FSCollection.sosAcknowledgements)
            .upsert(jsonDecode(raw) as Map<String, dynamic>);
      } catch (_) {
        failed.add(raw);
      }
    }
    await prefs.setStringList(_offlineAcksKey, failed);
    notifyListeners();
  }

  Future<void> _encodeOffline(GuardianRequestModel request) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_offlineRequestsKey) ?? const <String>[];
    list.add(jsonEncode(request.toMap()));
    await prefs.setStringList(_offlineRequestsKey, list);
  }

  Future<void> _restoreOfflineRequests() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_offlineRequestsKey);
    if (list == null) {
      return;
    }
    _outgoingRequests = list
        .map((raw) => GuardianRequestModel.fromMap(
            jsonDecode(raw) as Map<String, dynamic>))
        .toList();
  }

  @override
  void dispose() {
    _incomingController.close();
    _guardingController.close();
    _acksController.close();
    super.dispose();
  }
}
