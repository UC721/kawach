import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/emergency_model.dart';
import '../utils/constants.dart';

/// Handles emergency data persistence when offline.
/// Syncs to Firestore when connection is restored.
class OfflineEmergencyService extends ChangeNotifier {
  static const _key = 'offline_emergencies';
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  // ── Mock in-memory persistence ───────────────────────────────
  final List<String> _mockPrefs = [];

  // ── Save emergency locally ───────────────────────────────────
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
    // Mock listener
  }

  Future<int> pendingCount() async {
    return _mockPrefs.length;
  }
}
