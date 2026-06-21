import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/emergency_model.dart';
import '../models/location_update_model.dart';
import '../models/mesh_packet_model.dart';

class SosQueueSnapshot {
  const SosQueueSnapshot({
    required this.emergencies,
    required this.locations,
    required this.evidence,
    required this.meshPackets,
  });

  final int emergencies;
  final int locations;
  final int evidence;
  final int meshPackets;
}

class SosQueueManager extends ChangeNotifier {
  SosQueueManager._();

  static final SosQueueManager instance = SosQueueManager._();

  static const _emergencyQueueKey = 'kawach.queue.emergencies';
  static const _locationQueueKey = 'kawach.queue.locations';
  static const _evidenceQueueKey = 'kawach.queue.evidence';
  static const _meshQueueKey = 'kawach.queue.mesh';
  static const _activeEmergencyKey = 'kawach.active.emergency';

  SharedPreferences? _prefs;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) {
      return;
    }
    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;
  }

  Future<void> cacheActiveEmergency(EmergencyModel emergency) async {
    await initialize();
    await _prefs!.setString(_activeEmergencyKey, jsonEncode(emergency.toMap()));
  }

  Future<EmergencyModel?> getCachedActiveEmergency() async {
    await initialize();
    final raw = _prefs!.getString(_activeEmergencyKey);
    if (raw == null) {
      return null;
    }

    return EmergencyModel.fromMap(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }

  Future<void> clearCachedActiveEmergency() async {
    await initialize();
    await _prefs!.remove(_activeEmergencyKey);
  }

  Future<void> enqueueEmergency(EmergencyModel emergency) async {
    await _appendJson(_emergencyQueueKey, emergency.toMap());
  }

  Future<List<EmergencyModel>> takeQueuedEmergencies() async {
    return (await _readJsonList(_emergencyQueueKey))
        .map(EmergencyModel.fromMap)
        .toList();
  }

  Future<void> replaceQueuedEmergencies(List<EmergencyModel> items) async {
    await _writeJsonList(
      _emergencyQueueKey,
      items.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> enqueueLocation(LocationUpdateModel update) async {
    await _appendJson(_locationQueueKey, update.toMap());
  }

  Future<List<LocationUpdateModel>> takeQueuedLocations() async {
    return (await _readJsonList(_locationQueueKey))
        .map(LocationUpdateModel.fromMap)
        .toList();
  }

  Future<void> replaceQueuedLocations(List<LocationUpdateModel> items) async {
    await _writeJsonList(
      _locationQueueKey,
      items.map((item) => item.toMap()).toList(),
    );
  }

  Future<void> enqueueEvidenceJob(Map<String, dynamic> payload) async {
    await _appendJson(_evidenceQueueKey, payload);
  }

  Future<List<Map<String, dynamic>>> takeQueuedEvidenceJobs() {
    return _readJsonList(_evidenceQueueKey);
  }

  Future<void> replaceQueuedEvidenceJobs(List<Map<String, dynamic>> items) async {
    await _writeJsonList(_evidenceQueueKey, items);
  }

  Future<void> enqueueMeshPacket(MeshPacketModel packet) async {
    await _appendJson(_meshQueueKey, packet.toMap());
  }

  Future<List<MeshPacketModel>> takeQueuedMeshPackets() async {
    return (await _readJsonList(_meshQueueKey))
        .map(MeshPacketModel.fromMap)
        .toList();
  }

  Future<void> replaceQueuedMeshPackets(List<MeshPacketModel> items) async {
    await _writeJsonList(
      _meshQueueKey,
      items.map((item) => item.toMap()).toList(),
    );
  }

  Future<SosQueueSnapshot> snapshot() async {
    await initialize();
    return SosQueueSnapshot(
      emergencies: _prefs!.getStringList(_emergencyQueueKey)?.length ?? 0,
      locations: _prefs!.getStringList(_locationQueueKey)?.length ?? 0,
      evidence: _prefs!.getStringList(_evidenceQueueKey)?.length ?? 0,
      meshPackets: _prefs!.getStringList(_meshQueueKey)?.length ?? 0,
    );
  }

  Future<void> _appendJson(String key, Map<String, dynamic> payload) async {
    final list = await _readStringList(key);
    list.add(jsonEncode(payload));
    await _prefs!.setStringList(key, list);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> _readJsonList(String key) async {
    final items = await _readStringList(key);
    return items
        .map((item) => jsonDecode(item) as Map<String, dynamic>)
        .toList();
  }

  Future<void> _writeJsonList(
    String key,
    List<Map<String, dynamic>> value,
  ) async {
    await initialize();
    await _prefs!.setStringList(
      key,
      value.map(jsonEncode).toList(),
    );
    notifyListeners();
  }

  Future<List<String>> _readStringList(String key) async {
    await initialize();
    return List<String>.from(_prefs!.getStringList(key) ?? const <String>[]);
  }
}
