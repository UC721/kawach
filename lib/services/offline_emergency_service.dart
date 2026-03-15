import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/ai_prediction_model.dart';
import '../models/emergency_model.dart';
import 'ai/ai_model_service.dart';

class OfflineEmergencyService extends ChangeNotifier {
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  AIPrediction? _latestOfflineThreat;
  AIPrediction? get latestOfflineThreat => _latestOfflineThreat;

  // ── Mock in-memory persistence ───────────────────────────────
  final List<String> _mockPrefs = [];

  Future<void> saveEmergencyLocally(EmergencyModel emergency) async {
    _mockPrefs.add(jsonEncode(emergency.toMap()
        ..['emergencyId'] = emergency.emergencyId));
    notifyListeners();
  }

  // ── AI offline threat assessment ─────────────────────────────
  /// Runs an on-device threat assessment when the network is down.
  AIPrediction assessOfflineThreat({
    required AIModelService aiModelService,
    double? lastKnownRiskScore,
    bool motionAnomalyDetected = false,
    bool voicePanicDetected = false,
  }) {
    _latestOfflineThreat = aiModelService.assessOfflineThreat(
      hour: DateTime.now().hour,
      lastKnownRiskScore: lastKnownRiskScore,
      motionAnomalyDetected: motionAnomalyDetected,
      voicePanicDetected: voicePanicDetected,
    );
    notifyListeners();
    return _latestOfflineThreat!;
  }

  // ── Sync pending emergencies ─────────────────────────────────
  Future<void> syncPendingEmergencies() async {
    if (_mockPrefs.isEmpty) return;

    _isSyncing = true;
    notifyListeners();

    // Mock syncing delay
    await Future.delayed(const Duration(seconds: 1));
    _mockPrefs.clear();
    
    _isSyncing = false;
    notifyListeners();
  }

  // ── Listen to connectivity changes ───────────────────────────
  void listenForConnectivity() {
    // Mock listener
  }

  Future<int> pendingCount() async {
    return _mockPrefs.length;
  }
}
