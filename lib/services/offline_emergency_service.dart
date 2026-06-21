import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/emergency_model.dart';
import '../models/location_update_model.dart';
import '../utils/constants.dart';
import 'mesh_relay_service.dart';
import 'sos_queue_manager.dart';

class OfflineEmergencyService extends ChangeNotifier {
  OfflineEmergencyService({
    SosQueueManager? queueManager,
    MeshRelayService? meshRelayService,
  })  : _queueManager = queueManager ?? SosQueueManager.instance,
        _meshRelayService = meshRelayService;

  final SupabaseClient _db = Supabase.instance.client;
  final SosQueueManager _queueManager;
  final MeshRelayService? _meshRelayService;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  bool get isSyncing => _isSyncing;

  Future<void> saveEmergencyLocally(EmergencyModel emergency) async {
    await _queueManager.enqueueEmergency(emergency);
  }

  Future<void> saveLocationLocally(LocationUpdateModel update) async {
    await _queueManager.enqueueLocation(update);
  }

  Future<void> syncPendingEmergencies() async {
    if (_isSyncing) {
      return;
    }

    _isSyncing = true;
    notifyListeners();

    try {
      await _queueManager.initialize();
      await _syncEmergencyQueue();
      await _syncLocationQueue();
      await _meshRelayService?.flushQueuedPackets();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void listenForConnectivity() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((results) async {
      final hasNetwork = results.any((result) => result != ConnectivityResult.none);
      if (hasNetwork) {
        await syncPendingEmergencies();
      }
    });
  }

  Future<int> pendingCount() async {
    final snapshot = await _queueManager.snapshot();
    return snapshot.emergencies + snapshot.locations + snapshot.evidence + snapshot.meshPackets;
  }

  Future<void> _syncEmergencyQueue() async {
    final queued = await _queueManager.takeQueuedEmergencies();
    if (queued.isEmpty) {
      return;
    }

    final failed = <EmergencyModel>[];
    for (final emergency in queued) {
      try {
        await _db.from(FSCollection.emergencies).insert(emergency.toMap());
      } catch (_) {
        failed.add(emergency);
      }
    }
    await _queueManager.replaceQueuedEmergencies(failed);
  }

  Future<void> _syncLocationQueue() async {
    final queued = await _queueManager.takeQueuedLocations();
    if (queued.isEmpty) {
      return;
    }

    final failed = <LocationUpdateModel>[];
    for (final update in queued) {
      try {
        await _db.from(FSCollection.locations).insert(update.toMap());
      } catch (_) {
        failed.add(update);
      }
    }
    await _queueManager.replaceQueuedLocations(failed);
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
