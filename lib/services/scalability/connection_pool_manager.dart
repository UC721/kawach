import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/scalability_config_model.dart';

/// Manages Supabase client connections with automatic health-checks
/// and recovery.
///
/// In a millions-of-users deployment, every client-side connection
/// must be monitored so that stale or broken connections are
/// recycled quickly, keeping emergency SOS flows responsive.
class ConnectionPoolManager extends ChangeNotifier {
  final ScalabilityConfig _config;

  Timer? _healthCheckTimer;
  int _consecutiveFailures = 0;
  bool _isHealthy = true;
  DateTime? _lastSuccessfulCheck;

  bool get isHealthy => _isHealthy;
  DateTime? get lastSuccessfulCheck => _lastSuccessfulCheck;
  int get consecutiveFailures => _consecutiveFailures;

  ConnectionPoolManager({ScalabilityConfig? config})
      : _config = config ?? const ScalabilityConfig();

  /// Start periodic health-check pings.
  void startHealthChecks() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(
      _config.healthCheckInterval,
      (_) => _performHealthCheck(),
    );
  }

  /// Perform one health-check cycle.
  Future<bool> _performHealthCheck() async {
    try {
      // In production this would call Supabase's health endpoint or
      // execute a lightweight query (e.g. `SELECT 1`).
      // Here we simulate a successful check.
      _recordSuccess();
      return true;
    } catch (_) {
      _recordFailure();
      return false;
    }
  }

  void _recordSuccess() {
    _consecutiveFailures = 0;
    _lastSuccessfulCheck = DateTime.now();
    if (!_isHealthy) {
      _isHealthy = true;
      notifyListeners();
    }
  }

  void _recordFailure() {
    _consecutiveFailures++;
    if (_consecutiveFailures >= _config.maxHealthCheckFailures) {
      _isHealthy = false;
      notifyListeners();
    }
  }

  /// Manually mark the connection as unhealthy (e.g. after a
  /// failed critical request).
  void reportUnhealthy() {
    _isHealthy = false;
    _consecutiveFailures = _config.maxHealthCheckFailures;
    notifyListeners();
  }

  /// Force a recovery attempt.
  Future<bool> attemptRecovery() async {
    final ok = await _performHealthCheck();
    if (ok) {
      _isHealthy = true;
      _consecutiveFailures = 0;
      notifyListeners();
    }
    return ok;
  }

  /// Reset all tracking state.
  void reset() {
    _consecutiveFailures = 0;
    _isHealthy = true;
    _lastSuccessfulCheck = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _healthCheckTimer?.cancel();
    super.dispose();
  }
}
