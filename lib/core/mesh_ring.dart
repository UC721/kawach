import 'package:flutter/foundation.dart';

import '../models/guardian_model.dart';
import '../services/sms_service.dart';
import '../services/guardian_network_service.dart';
import '../services/offline_emergency_service.dart';

/// **Mesh ring** – middle ring for offline relay.
///
/// Responsible for:
/// • SMS emergency alerts to guardians (works via cellular)
/// • Nearby volunteer / guardian network alerts
/// • Syncing queued offline data when connectivity resumes
class MeshRing {
  /// Send emergency SMS to all guardians.
  Future<void> sendSmsAlerts({
    required SmsService smsService,
    required List<GuardianModel> guardians,
    required String userName,
    double? lat,
    double? lng,
  }) async {
    try {
      await smsService.sendEmergencySms(
        guardians: guardians,
        lat: lat,
        lng: lng,
        userName: userName,
      );
    } catch (e) {
      debugPrint('[MeshRing] SMS alerts failed: $e');
    }
  }

  /// Alert nearby volunteers in the guardian network.
  Future<void> alertNearbyVolunteers({
    required GuardianNetworkService guardianService,
    required String emergencyId,
    required String userId,
    required double lat,
    required double lng,
  }) async {
    try {
      await guardianService.alertNearbyVolunteers(
        emergencyId: emergencyId,
        userId: userId,
        lat: lat,
        lng: lng,
      );
    } catch (e) {
      debugPrint('[MeshRing] Volunteer alert failed: $e');
    }
  }

  /// Sync any pending offline emergencies to the backend.
  Future<void> syncPending(OfflineEmergencyService offlineService) async {
    try {
      await offlineService.syncPendingEmergencies();
    } catch (e) {
      debugPrint('[MeshRing] Sync failed: $e');
    }
  }
}
