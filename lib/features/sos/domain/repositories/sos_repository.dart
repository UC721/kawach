import '../entities/sos_alert.dart';

// ============================================================
// SosRepository – Abstract contract for SOS data operations
// ============================================================

/// Interface that the data layer must implement.
///
/// By depending on this abstraction the domain layer stays
/// independent of Supabase, local storage, or any other backend.
abstract class SosRepository {
  /// Persist a new SOS alert and return the created entity.
  Future<SosAlert> createAlert(SosAlert alert);

  /// Cancel a pending or active alert.
  Future<SosAlert> cancelAlert(String alertId);

  /// Resolve (close) an active alert.
  Future<SosAlert> resolveAlert(String alertId);

  /// Fetch the currently active alert for [userId], if any.
  Future<SosAlert?> getActiveAlert(String userId);

  /// Real-time stream of updates for a specific alert.
  Stream<SosAlert?> watchAlert(String alertId);

  /// Cache an alert locally for offline-first support.
  Future<void> cacheAlertLocally(SosAlert alert);

  /// Retrieve any locally cached alerts that haven't been synced.
  Future<List<SosAlert>> getPendingLocalAlerts();
}
