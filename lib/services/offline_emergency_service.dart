import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/emergency_model.dart';
import '../models/location_update_model.dart';
import '../utils/constants.dart';
import 'conflict_resolver.dart';
import 'mesh_relay_service.dart';
import 'sos_queue_manager.dart';

class SyncBucketResult {
  final String bucket;
  final int attempted;
  final int succeeded;
  final int failed;
  final int resolvedConflicts;
  final int skippedDuplicates;

  const SyncBucketResult({
    required this.bucket,
    required this.attempted,
    required this.succeeded,
    required this.failed,
    required this.resolvedConflicts,
    required this.skippedDuplicates,
  });
}

/// Offline-first pipeline: caches emergencies/locations/evidence/mesh locally,
/// re-syncs idempotently on reconnection and resolves conflicts where the
/// server row and the local copy disagree.
class OfflineEmergencyService extends ChangeNotifier {
  OfflineEmergencyService({
    SosQueueManager? queueManager,
    MeshRelayService? meshRelayService,
  })  : _queueManager = queueManager ?? SosQueueManager.instance,
        _meshRelayService = meshRelayService;

  static const String _syncStateKey = 'kawach.offline.sync_state.v1';

  final SupabaseClient _db = Supabase.instance.client;
  final SosQueueManager _queueManager;
  final MeshRelayService? _meshRelayService;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  DateTime? _lastSyncedAt;
  List<SyncBucketResult> _lastResults = [];
  bool _hasSyncedOnce = false;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncedAt => _lastSyncedAt;
  List<SyncBucketResult> get lastResults => _lastResults;
  bool get hasSyncedOnce => _hasSyncedOnce;

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

    final results = <SyncBucketResult>[];
    try {
      await _queueManager.initialize();
      results.add(await _syncEmergencyQueue());
      results.add(await _syncLocationQueue());
      results.add(await _syncEvidenceQueue());
      await _meshRelayService?.flushQueuedPackets();
      _lastResults = results;
      _lastSyncedAt = DateTime.now();
      _hasSyncedOnce = true;
      await _persistSyncState();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  void listenForConnectivity() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((results) async {
      final hasNetwork =
          results.any((result) => result != ConnectivityResult.none);
      if (hasNetwork) {
        await syncPendingEmergencies();
      }
    });
  }

  Future<int> pendingCount() async {
    final snapshot = await _queueManager.snapshot();
    return snapshot.emergencies +
        snapshot.locations +
        snapshot.evidence +
        snapshot.meshPackets;
  }

  Future<void> restoreSyncState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_syncStateKey);
    if (raw == null) {
      return;
    }
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _lastSyncedAt = DateTime.tryParse(data['lastSyncedAt'] ?? '');
      _hasSyncedOnce = data['hasSyncedOnce'] ?? false;
      final results = data['results'] as List? ?? const [];
      _lastResults = results
          .map((r) => _resultFromMap(r as Map<String, dynamic>))
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _persistSyncState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _syncStateKey,
      jsonEncode({
        'lastSyncedAt': _lastSyncedAt?.toIso8601String(),
        'hasSyncedOnce': _hasSyncedOnce,
        'results': _lastResults.map(_resultToMap).toList(),
      }),
    );
  }

  Future<SyncBucketResult> _syncEmergencyQueue() async {
    final queuedRaw = await _queueManager.takeQueuedEmergencies();
    final queued = ConflictResolver.dedupeEmergencies(queuedRaw);
    final skipped = queuedRaw.length - queued.length;
    if (queued.isEmpty) {
      return _emptyResult('emergencies', skippedDuplicates: skipped);
    }

    var succeeded = 0;
    var failed = 0;
    var resolvedConflicts = 0;
    final failures = <EmergencyModel>[];

    for (final emergency in queued) {
      try {
        await _db.from(FSCollection.emergencies).upsert(
              emergency.toMap(),
              onConflict: 'emergency_id',
            );
        succeeded++;
      } catch (_) {
        // Idempotent insert failed — try the conflict-resolution path:
        // load the server row, merge, and update instead of inserting.
        try {
          final remote = await _fetchRemoteEmergency(emergency.emergencyId);
          final merged = ConflictResolver.resolveEmergencyConflict(
            local: emergency,
            remote: remote,
          );
          await _db
              .from(FSCollection.emergencies)
              .update(merged.toMap())
              .eq('emergency_id', emergency.emergencyId);
          succeeded++;
          resolvedConflicts++;
        } catch (_) {
          failures.add(emergency);
          failed++;
        }
      }
    }

    await _queueManager.replaceQueuedEmergencies(failures);
    return SyncBucketResult(
      bucket: 'emergencies',
      attempted: queued.length,
      succeeded: succeeded,
      failed: failed,
      resolvedConflicts: resolvedConflicts,
      skippedDuplicates: skipped,
    );
  }

  Future<EmergencyModel> _fetchRemoteEmergency(String emergencyId) async {
    final response = await _db
        .from(FSCollection.emergencies)
        .select()
        .eq('emergency_id', emergencyId)
        .maybeSingle();
    return EmergencyModel.fromMap(response ?? <String, dynamic>{});
  }

  Future<SyncBucketResult> _syncLocationQueue() async {
    final queued = await _queueManager.takeQueuedLocations();
    if (queued.isEmpty) {
      return _emptyResult('locations');
    }

    var succeeded = 0;
    var failed = 0;
    final failures = <LocationUpdateModel>[];

    for (final update in queued) {
      try {
        await _db.from(FSCollection.locations).insert(update.toMap());
        succeeded++;
      } catch (_) {
        failures.add(update);
        failed++;
      }
    }
    await _queueManager.replaceQueuedLocations(failures);
    return SyncBucketResult(
      bucket: 'locations',
      attempted: queued.length,
      succeeded: succeeded,
      failed: failed,
      resolvedConflicts: 0,
      skippedDuplicates: 0,
    );
  }

  Future<SyncBucketResult> _syncEvidenceQueue() async {
    final queued = await _queueManager.takeQueuedEvidenceJobs();
    if (queued.isEmpty) {
      return _emptyResult('evidence');
    }

    var succeeded = 0;
    var failed = 0;
    final failures = <Map<String, dynamic>>[];

    for (final job in queued) {
      try {
        final emergencyId = job['emergency_id'];
        await _db.from(FSCollection.evidenceVault).upsert(
              job,
              onConflict: 'evidence_id',
            );
        await _db.from(FSCollection.emergencies).update({
          if (job['audio_url'] != null) 'audio_url': job['audio_url'],
          if (job['video_url'] != null) 'video_url': job['video_url'],
        }).eq('emergency_id', emergencyId);
        succeeded++;
      } catch (_) {
        failures.add(job);
        failed++;
      }
    }
    await _queueManager.replaceQueuedEvidenceJobs(failures);
    return SyncBucketResult(
      bucket: 'evidence',
      attempted: queued.length,
      succeeded: succeeded,
      failed: failed,
      resolvedConflicts: 0,
      skippedDuplicates: 0,
    );
  }

  SyncBucketResult _emptyResult(String bucket, {int skippedDuplicates = 0}) {
    return SyncBucketResult(
      bucket: bucket,
      attempted: 0,
      succeeded: 0,
      failed: 0,
      resolvedConflicts: 0,
      skippedDuplicates: skippedDuplicates,
    );
  }

  Map<String, dynamic> _resultToMap(SyncBucketResult r) => {
        'bucket': r.bucket,
        'attempted': r.attempted,
        'succeeded': r.succeeded,
        'failed': r.failed,
        'resolvedConflicts': r.resolvedConflicts,
        'skippedDuplicates': r.skippedDuplicates,
      };

  SyncBucketResult _resultFromMap(Map<String, dynamic> m) => SyncBucketResult(
        bucket: m['bucket'] ?? '',
        attempted: m['attempted'] ?? 0,
        succeeded: m['succeeded'] ?? 0,
        failed: m['failed'] ?? 0,
        resolvedConflicts: m['resolvedConflicts'] ?? 0,
        skippedDuplicates: m['skippedDuplicates'] ?? 0,
      );

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
