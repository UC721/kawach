import 'dart:math';

// ============================================================
// MovementAnalyzer – Movement pattern classification (Module 3)
// ============================================================

/// Classifies user movement patterns (walking, running, stationary,
/// vehicle) from accelerometer & GPS data.
///
/// The classification feeds into [AnomalyDetector] and [FollowMeDetector].
class MovementAnalyzer {
  MovementType _currentType = MovementType.unknown;
  MovementType get currentMovementType => _currentType;

  final List<_SpeedSample> _speedHistory = [];
  static const int _windowSize = 20;

  /// Update with a new GPS speed sample (m/s).
  MovementType analyzeSpeed(double speedMs) {
    _speedHistory.add(_SpeedSample(speedMs, DateTime.now()));
    if (_speedHistory.length > _windowSize) {
      _speedHistory.removeAt(0);
    }
    _currentType = _classify(speedMs);
    return _currentType;
  }

  /// Update with accelerometer magnitude data.
  MovementType analyzeAcceleration(double magnitude) {
    if (magnitude < 1.5) return MovementType.stationary;
    if (magnitude < 5.0) return MovementType.walking;
    if (magnitude < 12.0) return MovementType.running;
    return MovementType.erratic;
  }

  /// Detect sudden stops that may indicate an abduction scenario.
  bool detectSuddenStop() {
    if (_speedHistory.length < 3) return false;
    final recent = _speedHistory.sublist(_speedHistory.length - 3);
    return recent.first.speed > 5.0 && recent.last.speed < 0.5;
  }

  /// Detect sudden acceleration that may indicate being grabbed.
  bool detectSuddenAcceleration() {
    if (_speedHistory.length < 3) return false;
    final recent = _speedHistory.sublist(_speedHistory.length - 3);
    return recent.first.speed < 1.0 && recent.last.speed > 8.0;
  }

  MovementType _classify(double speedMs) {
    if (speedMs < 0.5) return MovementType.stationary;
    if (speedMs < 2.0) return MovementType.walking;
    if (speedMs < 6.0) return MovementType.running;
    if (speedMs < 30.0) return MovementType.vehicle;
    return MovementType.erratic;
  }
}

enum MovementType { stationary, walking, running, vehicle, erratic, unknown }

class _SpeedSample {
  final double speed;
  final DateTime timestamp;
  const _SpeedSample(this.speed, this.timestamp);
}
