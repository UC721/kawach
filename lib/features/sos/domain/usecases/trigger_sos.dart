import '../entities/sos_alert.dart';
import '../repositories/sos_repository.dart';

// ============================================================
// TriggerSos – Use case: initiate an SOS alert
// ============================================================

/// Orchestrates the creation of a new SOS alert.
///
/// Validates preconditions (no duplicate active alert) before delegating
/// persistence to the repository.
class TriggerSos {
  final SosRepository _repository;

  const TriggerSos(this._repository);

  Future<SosAlert> call({
    required String userId,
    required SosTriggerType trigger,
    double? latitude,
    double? longitude,
  }) async {
    // Prevent duplicate active alerts
    final existing = await _repository.getActiveAlert(userId);
    if (existing != null) return existing;

    final alert = SosAlert(
      id: '', // Will be assigned by the data layer
      userId: userId,
      status: SosAlertStatus.active,
      triggeredBy: trigger,
      latitude: latitude,
      longitude: longitude,
      createdAt: DateTime.now(),
    );

    return _repository.createAlert(alert);
  }
}
