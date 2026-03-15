import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/emergency_model.dart';
import '../services/location_service.dart';
import '../services/audio_service.dart';
import '../services/camera_evidence_service.dart';
import '../services/siren_service.dart';
import '../services/offline_emergency_service.dart';

/// **Edge ring** – innermost ring, always available on-device.
///
/// Responsible for:
/// • GPS location capture & tracking
/// • Audio / video evidence recording (local files)
/// • Siren activation (alarm + torch strobe)
/// • Caching emergencies locally for later sync
class EdgeRing {
  /// Capture current GPS position.
  Future<Position?> captureLocation(LocationService locationService) async {
    try {
      return await locationService.getCurrentPosition();
    } catch (e) {
      debugPrint('[EdgeRing] Location capture failed: $e');
      return null;
    }
  }

  /// Begin continuous GPS tracking for an active emergency.
  void startTracking(
    LocationService locationService,
    String userId,
    String emergencyId,
  ) {
    try {
      locationService.startTracking(userId, emergencyId);
    } catch (e) {
      debugPrint('[EdgeRing] Tracking start failed: $e');
    }
  }

  /// Start audio recording for evidence (local file).
  Future<void> startAudioRecording(AudioService audioService) async {
    try {
      await audioService.startRecording();
    } catch (e) {
      debugPrint('[EdgeRing] Audio recording failed: $e');
    }
  }

  /// Start video capture for evidence (local file).
  Future<void> startVideoCapture(CameraEvidenceService cameraService) async {
    try {
      await cameraService.initializeCamera();
      await cameraService.startVideoRecording();
    } catch (e) {
      debugPrint('[EdgeRing] Video capture failed: $e');
    }
  }

  /// Activate siren (audio alarm + torch strobe).
  Future<void> activateSiren(SirenService sirenService) async {
    try {
      await sirenService.startSiren();
    } catch (e) {
      debugPrint('[EdgeRing] Siren activation failed: $e');
    }
  }

  /// Persist emergency data locally when outer rings are unavailable.
  Future<void> cacheLocally(
    OfflineEmergencyService offlineService,
    EmergencyModel emergency,
  ) async {
    await offlineService.saveEmergencyLocally(emergency);
  }
}
