import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

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

/// Central emergency pipeline – all SOS triggers call [triggerEmergency].
class EmergencyService extends ChangeNotifier {
  SupabaseClient get _db => Supabase.instance.client;
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
  }) async {
    if (_isActive) return; // Prevent duplicate triggers
    _isActive = true;
    _stealthMode = false;
    notifyListeners();

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    // 1. Get current location
    Position? pos;
    try {
      pos = await locationService.getCurrentPosition();
    } catch (_) {}

    final lat = pos?.latitude;
    final lng = pos?.longitude;

    // 2. Create emergency document in Firestore
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

    try {
      await _db
          .from(FSCollection.emergencies)
          .insert(emergency.toMap());
    } catch (e) {
      // Offline fallback – store locally
      await offlineService.saveEmergencyLocally(emergency);
    }

    _activeEmergency = emergency;
    notifyListeners();

    // 3. Start live GPS tracking
    unawaited(locationService.startTracking(userId, emergencyId));

    // 4. Start audio recording & upload
    unawaited(_startAudioEvidence(
        audioService, vaultService, userId, emergencyId));

    // 5. Start camera evidence capture
    unawaited(_startVideoEvidence(
        cameraService, vaultService, userId, emergencyId));

    // 6. Start live video stream
    unawaited(streamService.startStream(userId, emergencyId));

    // 7. Send push notifications to guardians
    final guardians = await userService.getGuardians(userId);
    unawaited(notificationService.notifyGuardians(
      guardians: guardians,
      emergencyId: emergencyId,
      userId: userId,
      lat: lat,
      lng: lng,
    ));

    // 8. SMS backup
    unawaited(smsService.sendEmergencySms(
      guardians: guardians,
      lat: lat,
      lng: lng,
      userName: userService.currentUserModel?.name ?? 'User',
    ));

    // 9. Auto-activate stealth mode after 5s
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
