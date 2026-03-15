import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../core/ring_coordinator.dart';
import '../models/emergency_model.dart';
import '../utils/constants.dart';
import 'location_service.dart';
import 'audio_service.dart';
import 'camera_evidence_service.dart';
import 'evidence_vault_service.dart';
import 'notification_service.dart';
import 'sms_service.dart';
import 'live_stream_service.dart';
import 'user_service.dart';
import 'offline_emergency_service.dart';
import 'guardian_network_service.dart';

/// Central emergency pipeline – all SOS triggers call [triggerEmergency].
///
/// Uses [RingCoordinator] to determine which rings are available and
/// executes the appropriate actions on each ring:
///
/// • **Edge** (always): GPS, audio/video recording, local cache
/// • **Mesh** (when available): SMS alerts, guardian network relay
/// • **Cloud** (when available): Supabase persist, push notifications, live stream
class EmergencyService extends ChangeNotifier {
  final SupabaseClient _db = Supabase.instance.client;
  final _uuid = const Uuid();

  EmergencyModel? _activeEmergency;
  bool _isActive = false;
  bool _stealthMode = false;

  EmergencyModel? get activeEmergency => _activeEmergency;
  bool get isActive => _isActive;
  bool get stealthMode => _stealthMode;

  // ── TRIGGER EMERGENCY ────────────────────────────────────────
  Future<void> triggerEmergency({
    required EmergencyTrigger trigger,
    required LocationService locationService,
    required AudioService audioService,
    required CameraEvidenceService cameraService,
    required EvidenceVaultService vaultService,
    required NotificationService notificationService,
    required SmsService smsService,
    required LiveStreamService streamService,
    required UserService userService,
    required OfflineEmergencyService offlineService,
    RingCoordinator? ringCoordinator,
    GuardianNetworkService? guardianNetworkService,
  }) async {
    if (_isActive) return; // Prevent duplicate triggers
    _isActive = true;
    _stealthMode = false;
    notifyListeners();

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // ── EDGE RING (always available) ─────────────────────────
    // 1. Get current location
    Position? pos;
    if (ringCoordinator != null) {
      pos = await ringCoordinator.edgeRing.captureLocation(locationService);
    } else {
      try {
        pos = await locationService.getCurrentPosition();
      } catch (_) {}
    }

    final lat = pos?.latitude;
    final lng = pos?.longitude;

    // 2. Create emergency document
    final emergencyId = _uuid.v4();
    final emergency = EmergencyModel(
      emergencyId: emergencyId,
      userId: userId,
      status: EmergencyStatus.active,
      triggeredBy: trigger,
      lat: lat,
      lng: lng,
      createdAt: DateTime.now(),
    );

    // 3. Persist: Cloud ring first, fall back to Edge local cache
    if (ringCoordinator != null && ringCoordinator.isCloudAvailable) {
      final persisted =
          await ringCoordinator.cloudRing.persistEmergency(emergency);
      if (!persisted) {
        await ringCoordinator.edgeRing.cacheLocally(offlineService, emergency);
      }
    } else if (ringCoordinator != null) {
      // Cloud unavailable – cache locally via Edge ring
      await ringCoordinator.edgeRing.cacheLocally(offlineService, emergency);
    } else {
      // Legacy path (no coordinator)
      try {
        await _db.from(FSCollection.emergencies).insert(emergency.toMap());
      } catch (e) {
        await offlineService.saveEmergencyLocally(emergency);
      }
    }

    _activeEmergency = emergency;
    notifyListeners();

    // 4. Start live GPS tracking (Edge)
    if (ringCoordinator != null) {
      ringCoordinator.edgeRing
          .startTracking(locationService, userId, emergencyId);
    } else {
      unawaited(locationService.startTracking(userId, emergencyId));
    }

    // 5. Start audio recording & upload (Edge + Cloud)
    unawaited(_startAudioEvidence(
        audioService, vaultService, userId, emergencyId));

    // 6. Start camera evidence capture (Edge + Cloud)
    unawaited(_startVideoEvidence(
        cameraService, vaultService, userId, emergencyId));

    // ── CLOUD RING ───────────────────────────────────────────
    final guardians = await userService.getGuardians(userId);

    if (ringCoordinator != null && ringCoordinator.isCloudAvailable) {
      // 7. Start live video stream
      unawaited(ringCoordinator.cloudRing.startLiveStream(
        streamService: streamService,
        userId: userId,
        emergencyId: emergencyId,
      ));

      // 8. Send push notifications to guardians
      unawaited(ringCoordinator.cloudRing.notifyGuardians(
        notificationService: notificationService,
        guardians: guardians,
        emergencyId: emergencyId,
        userId: userId,
        lat: lat,
        lng: lng,
      ));
    } else if (ringCoordinator == null) {
      // Legacy path
      unawaited(streamService.startStream(userId, emergencyId));
      unawaited(notificationService.notifyGuardians(
        guardians: guardians,
        emergencyId: emergencyId,
        userId: userId,
        lat: lat,
        lng: lng,
      ));
    }

    // ── MESH RING ────────────────────────────────────────────
    if (ringCoordinator != null) {
      // 9. SMS backup (works via cellular, independent of internet)
      unawaited(ringCoordinator.meshRing.sendSmsAlerts(
        smsService: smsService,
        guardians: guardians,
        userName: userService.currentUserModel?.name ?? 'User',
        lat: lat,
        lng: lng,
      ));

      // 10. Alert nearby volunteers
      if (ringCoordinator.isMeshAvailable &&
          guardianNetworkService != null &&
          lat != null &&
          lng != null) {
        unawaited(ringCoordinator.meshRing.alertNearbyVolunteers(
          guardianService: guardianNetworkService,
          emergencyId: emergencyId,
          userId: userId,
          lat: lat,
          lng: lng,
        ));
      }
    } else {
      // Legacy path
      unawaited(smsService.sendEmergencySms(
        guardians: guardians,
        lat: lat,
        lng: lng,
        userName: userService.currentUserModel?.name ?? 'User',
      ));
    }

    // 11. Auto-activate stealth mode after 5s
    Timer(const Duration(seconds: 5), () {
      activateStealthMode();
    });
  }

  // ── AUDIO EVIDENCE ───────────────────────────────────────────
  Future<void> _startAudioEvidence(
    AudioService audioService,
    EvidenceVaultService vaultService,
    String userId,
    String emergencyId,
  ) async {
    try {
      await audioService.startRecording(); // Ignored returned path
      // Record for 5 minutes then upload
      await Future.delayed(const Duration(minutes: 5));
      final audioUrl = await audioService.stopAndUpload(
          userId: userId, emergencyId: emergencyId);
      if (audioUrl != null) {
        await vaultService.saveEvidence(
            userId: userId,
            emergencyId: emergencyId,
            audioUrl: audioUrl);
        await _db
            .from(FSCollection.emergencies)
            .update({'audioUrl': audioUrl})
            .eq('emergencyId', emergencyId);
      }
    } catch (_) {}
  }

  // ── VIDEO EVIDENCE ───────────────────────────────────────────
  Future<void> _startVideoEvidence(
    CameraEvidenceService cameraService,
    EvidenceVaultService vaultService,
    String userId,
    String emergencyId,
  ) async {
    try {
      final videoUrl = await cameraService.captureAndUpload(
          userId: userId, emergencyId: emergencyId);
      if (videoUrl != null) {
        await vaultService.saveEvidence(
            userId: userId,
            emergencyId: emergencyId,
            videoUrl: videoUrl);
        await _db
            .from(FSCollection.emergencies)
            .update({'videoUrl': videoUrl})
            .eq('emergencyId', emergencyId);
      }
    } catch (_) {}
  }

  // ── STEALTH MODE ─────────────────────────────────────────────
  void activateStealthMode() {
    _stealthMode = true;
    notifyListeners();
  }

  void deactivateStealthMode() {
    _stealthMode = false;
    notifyListeners();
  }

  // ── RESOLVE EMERGENCY ────────────────────────────────────────
  Future<void> resolveEmergency({
    required LocationService locationService,
    required AudioService audioService,
    required LiveStreamService streamService,
  }) async {
    if (_activeEmergency == null) return;
    final emergencyId = _activeEmergency!.emergencyId;

    await locationService.stopTracking();
    await audioService.stopRecording();
    await streamService.stopStream();

    await _db
        .from(FSCollection.emergencies)
        .update({
      'status': EmergencyStatus.resolved.name,
      'resolvedAt': DateTime.now().toIso8601String(),
    }).eq('emergencyId', emergencyId);

    _activeEmergency = null;
    _isActive = false;
    _stealthMode = false;
    notifyListeners();
  }

  // ── STREAM ACTIVE EMERGENCY ──────────────────────────────────
  Stream<EmergencyModel?> streamEmergency(String emergencyId) {
    return _db
        .from(FSCollection.emergencies)
        .stream(primaryKey: ['emergencyId'])
        .eq('emergencyId', emergencyId)
        .map((docs) => docs.isNotEmpty ? EmergencyModel.fromMap(docs.first) : null);
  }

  // ── GUARDIAN VIEW: stream latest active emergency of user ───
  Stream<EmergencyModel?> streamActiveEmergencyForUser(String userId) {
    return _db
        .from(FSCollection.emergencies)
        .stream(primaryKey: ['emergencyId'])
        .eq('userId', userId)
        .map((docs) {
          final activeDocs = docs.where((d) => d['status'] == EmergencyStatus.active.name).toList();
          activeDocs.sort((a, b) {
            final dateA = a['created_at'] ?? a['createdAt'];
            final dateB = b['created_at'] ?? b['createdAt'];
            return (dateB as String).compareTo(dateA as String);
          });
          return activeDocs.isNotEmpty
              ? EmergencyModel.fromMap(activeDocs.first)
              : null;
        });
  }
}
