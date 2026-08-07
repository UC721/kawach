import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/emergency_model.dart';
import '../utils/constants.dart';
import 'audio_service.dart';
import 'background_sos_service.dart';
import 'camera_evidence_service.dart';
import 'evidence_vault_service.dart';
import 'guardian_network_service.dart';
import 'live_stream_service.dart';
import 'location_service.dart';
import 'mesh_relay_service.dart';
import 'notification_service.dart';
import 'offline_emergency_service.dart';
import 'sms_service.dart';
import 'sos_queue_manager.dart';
import 'user_service.dart';

class EmergencyService extends ChangeNotifier {
  EmergencyService({
    SosQueueManager? queueManager,
  }) : _queueManager = queueManager ?? SosQueueManager.instance;

  final SupabaseClient _db = Supabase.instance.client;
  final Uuid _uuid = const Uuid();
  final SosQueueManager _queueManager;

  EmergencyModel? _activeEmergency;
  bool _isActive = false;
  bool _stealthMode = false;

  EmergencyModel? get activeEmergency => _activeEmergency;
  bool get isActive => _isActive;
  bool get stealthMode => _stealthMode;

  Future<void> restoreActiveEmergency() async {
    final cached = await _queueManager.getCachedActiveEmergency();
    if (cached == null || cached.status != EmergencyStatus.active) {
      return;
    }
    _activeEmergency = cached;
    _isActive = true;
    notifyListeners();
  }

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
    required GuardianNetworkService guardianNetworkService,
    required MeshRelayService meshRelayService,
    required BackgroundSosService backgroundSosService,
  }) async {
    if (_isActive) {
      return;
    }

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _isActive = false;
      notifyListeners();
      return;
    }

    _isActive = true;
    _stealthMode = false;
    notifyListeners();

    Position? position;
    try {
      position = await locationService.getCurrentPosition();
    } catch (_) {
      position = null;
    }

    final emergency = EmergencyModel(
      emergencyId: _uuid.v4(),
      userId: userId,
      status: EmergencyStatus.active,
      triggeredBy: trigger,
      lat: position?.latitude,
      lng: position?.longitude,
      createdAt: DateTime.now(),
    );

    try {
      await _db.from(FSCollection.emergencies).insert(emergency.toMap());
    } catch (_) {
      await offlineService.saveEmergencyLocally(emergency);
    }

    _activeEmergency = emergency;
    await _queueManager.cacheActiveEmergency(emergency);
    notifyListeners();

    unawaited(
      backgroundSosService.start(
        emergencyId: emergency.emergencyId,
        title: 'KAWACH SOS active',
        body: 'Live tracking and evidence capture are running',
      ),
    );
    unawaited(locationService.startTracking(userId, emergency.emergencyId));
    unawaited(
      _startAudioEvidence(
        audioService,
        vaultService,
        userId,
        emergency.emergencyId,
      ),
    );
    unawaited(
      _startVisualEvidence(
        cameraService,
        vaultService,
        userId,
        emergency.emergencyId,
      ),
    );
    unawaited(streamService.startStream(userId, emergency.emergencyId));

    final guardians = await userService.getGuardians(userId);
    final userName = userService.currentUserModel?.name ?? 'User';

    unawaited(
      notificationService.notifyGuardians(
        guardians: guardians,
        emergencyId: emergency.emergencyId,
        userId: userId,
        lat: emergency.lat,
        lng: emergency.lng,
      ),
    );
    unawaited(
      smsService.sendEmergencySms(
        guardians: guardians,
        lat: emergency.lat,
        lng: emergency.lng,
        userName: userName,
      ),
    );

    if (emergency.lat != null && emergency.lng != null) {
      unawaited(
        guardianNetworkService.alertNearbyVolunteers(
          emergencyId: emergency.emergencyId,
          userId: userId,
          userName: userName,
          lat: emergency.lat!,
          lng: emergency.lng!,
        ),
      );
    }

    unawaited(
      meshRelayService.broadcastEmergency(
        emergency: emergency,
        userName: userName,
      ),
    );

    Timer(const Duration(seconds: 5), activateStealthMode);
  }

  Future<void> resolveEmergency({
    required LocationService locationService,
    required AudioService audioService,
    required LiveStreamService streamService,
    required BackgroundSosService backgroundSosService,
    required MeshRelayService meshRelayService,
  }) async {
    if (_activeEmergency == null) {
      return;
    }

    final emergencyId = _activeEmergency!.emergencyId;

    await locationService.stopTracking();
    await audioService.stopRecording();
    await streamService.stopStream();
    await backgroundSosService.stop();
    await meshRelayService.stopRelay();

    await _db.from(FSCollection.emergencies).update({
      'status': EmergencyStatus.resolved.name,
      'resolved_at': DateTime.now().toIso8601String(),
    }).eq('emergency_id', emergencyId);

    await _queueManager.clearCachedActiveEmergency();
    _activeEmergency = null;
    _isActive = false;
    _stealthMode = false;
    notifyListeners();
  }

  void activateStealthMode() {
    _stealthMode = true;
    notifyListeners();
  }

  void deactivateStealthMode() {
    _stealthMode = false;
    notifyListeners();
  }

  Stream<EmergencyModel?> streamEmergency(String emergencyId) {
    return _db
        .from(FSCollection.emergencies)
        .stream(primaryKey: ['emergency_id'])
        .eq('emergency_id', emergencyId)
        .map((docs) =>
            docs.isNotEmpty ? EmergencyModel.fromMap(docs.first) : null);
  }

  Stream<EmergencyModel?> streamActiveEmergencyForUser(String userId) {
    return _db
        .from(FSCollection.emergencies)
        .stream(primaryKey: ['emergency_id'])
        .eq('user_id', userId)
        .map((docs) {
          final activeDocs = docs
              .where((doc) => doc['status'] == EmergencyStatus.active.name)
              .toList();
          activeDocs.sort((left, right) {
            final leftDate = left['created_at'] as String? ?? '';
            final rightDate = right['created_at'] as String? ?? '';
            return rightDate.compareTo(leftDate);
          });
          return activeDocs.isNotEmpty
              ? EmergencyModel.fromMap(activeDocs.first)
              : null;
        });
  }

  Future<void> _startAudioEvidence(
    AudioService audioService,
    EvidenceVaultService vaultService,
    String userId,
    String emergencyId,
  ) async {
    try {
      await audioService.startRecording();
      await Future.delayed(const Duration(minutes: 2));
      final audioUrl = await audioService.stopAndUpload(
        userId: userId,
        emergencyId: emergencyId,
      );
      if (audioUrl != null) {
        await vaultService.saveEvidence(
          userId: userId,
          emergencyId: emergencyId,
          audioUrl: audioUrl,
        );
        await _db.from(FSCollection.emergencies).update({
          'audio_url': audioUrl,
        }).eq('emergency_id', emergencyId);
      }
    } catch (_) {}
  }

  Future<void> _startVisualEvidence(
    CameraEvidenceService cameraService,
    EvidenceVaultService vaultService,
    String userId,
    String emergencyId,
  ) async {
    try {
      final videoUrl = await cameraService.captureAndUpload(
        userId: userId,
        emergencyId: emergencyId,
      );
      final photoUrl = await cameraService.capturePhoto(
        userId: userId,
        emergencyId: emergencyId,
      );

      if (videoUrl != null || photoUrl != null) {
        await vaultService.saveEvidence(
          userId: userId,
          emergencyId: emergencyId,
          videoUrl: videoUrl ?? photoUrl,
        );
      }

      if (videoUrl != null) {
        await _db.from(FSCollection.emergencies).update({
          'video_url': videoUrl,
        }).eq('emergency_id', emergencyId);
      }
    } catch (_) {}
  }
}
