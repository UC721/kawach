import '../../../../core/network/connectivity_service.dart';
import '../../domain/entities/sos_alert.dart';
import '../../domain/repositories/sos_repository.dart';
import '../datasources/sos_local_datasource.dart';
import '../datasources/sos_remote_datasource.dart';
import '../models/sos_alert_model.dart';

// ============================================================
// SosRepositoryImpl – Concrete SOS repository with offline fallback
// ============================================================

class SosRepositoryImpl implements SosRepository {
  final SosRemoteDatasource _remote;
  final SosLocalDatasource _local;
  final ConnectivityService _connectivity;

  SosRepositoryImpl({
    required SosRemoteDatasource remote,
    required SosLocalDatasource local,
    required ConnectivityService connectivity,
  })  : _remote = remote,
        _local = local,
        _connectivity = connectivity;

  @override
  Future<SosAlert> createAlert(SosAlert alert) async {
    final model = SosAlertModel.fromEntity(alert);

    if (await _connectivity.checkConnectivity()) {
      return _remote.createAlert(model);
    }

    // Offline fallback – cache locally
    await _local.cacheAlert(model);
    return alert;
  }

  @override
  Future<SosAlert> cancelAlert(String alertId) async {
    return _remote.updateAlert(alertId, {
      'status': SosAlertStatus.cancelled.name,
      'resolved_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<SosAlert> resolveAlert(String alertId) async {
    return _remote.updateAlert(alertId, {
      'status': SosAlertStatus.resolved.name,
      'resolved_at': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<SosAlert?> getActiveAlert(String userId) {
    return _remote.getActiveAlert(userId);
  }

  @override
  Stream<SosAlert?> watchAlert(String alertId) {
    return _remote.watchAlert(alertId);
  }

  @override
  Future<void> cacheAlertLocally(SosAlert alert) {
    return _local.cacheAlert(SosAlertModel.fromEntity(alert));
  }

  @override
  Future<List<SosAlert>> getPendingLocalAlerts() {
    return _local.getPendingAlerts();
  }
}
