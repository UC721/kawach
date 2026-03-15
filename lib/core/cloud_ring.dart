import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/emergency_model.dart';
import '../models/guardian_model.dart';
import '../services/notification_service.dart';
import '../services/live_stream_service.dart';
import '../utils/constants.dart';

/// **Cloud ring** – outermost ring, requires Supabase backend.
///
/// Responsible for:
/// • Persisting emergency records to the database
/// • Sending push notifications to guardians
/// • Starting live video streams
/// • Real-time data synchronization
class CloudRing {
  final SupabaseClient _db;

  CloudRing({SupabaseClient? db})
      : _db = db ?? Supabase.instance.client;

  /// Persist the emergency record to Supabase.
  ///
  /// Returns `true` on success, `false` if the backend is unreachable.
  Future<bool> persistEmergency(EmergencyModel emergency) async {
    try {
      await _db.from(FSCollection.emergencies).insert(emergency.toMap());
      return true;
    } catch (e) {
      debugPrint('[CloudRing] DB persist failed: $e');
      return false;
    }
  }

  /// Send push notifications to all guardians.
  Future<void> notifyGuardians({
    required NotificationService notificationService,
    required List<GuardianModel> guardians,
    required String emergencyId,
    required String userId,
    double? lat,
    double? lng,
  }) async {
    try {
      await notificationService.notifyGuardians(
        guardians: guardians,
        emergencyId: emergencyId,
        userId: userId,
        lat: lat,
        lng: lng,
      );
    } catch (e) {
      debugPrint('[CloudRing] Push notification failed: $e');
    }
  }

  /// Start live video stream for guardians.
  Future<void> startLiveStream({
    required LiveStreamService streamService,
    required String userId,
    required String emergencyId,
  }) async {
    try {
      await streamService.startStream(userId, emergencyId);
    } catch (e) {
      debugPrint('[CloudRing] Live stream failed: $e');
    }
  }
}
