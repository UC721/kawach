import '../entities/sos_alert.dart';
import '../repositories/sos_repository.dart';

// ============================================================
// CancelSos – Use case: cancel an active SOS alert
// ============================================================

/// Cancels an in-progress SOS alert within the countdown window.
class CancelSos {
  final SosRepository _repository;

  const CancelSos(this._repository);

  Future<SosAlert> call(String alertId) {
    return _repository.cancelAlert(alertId);
  }
}
