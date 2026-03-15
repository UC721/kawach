import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../models/emergency_model.dart';

class OfflineEmergencyService extends ChangeNotifier {
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  // ── Mock in-memory persistence ───────────────────────────────
  final List<String> _mockPrefs = [];

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  Future<void> saveEmergencyLocally(EmergencyModel emergency) async {
    _mockPrefs.add(jsonEncode(emergency.toMap()
        ..['emergencyId'] = emergency.emergencyId));
    notifyListeners();
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
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((results) async {
      final hasNetwork = results.any((r) => r != ConnectivityResult.none);
      if (hasNetwork) {
        await syncPendingEmergencies();
      }
    });
  }

  Future<int> pendingCount() async {
    return _mockPrefs.length;
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }
}
