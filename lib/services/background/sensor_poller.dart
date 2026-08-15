import 'dart:async';

// ============================================================
// SensorPoller – Periodic sensor data collection
// ============================================================

/// Polls device sensors at configurable intervals and feeds data
/// to the anomaly detection pipeline.
///
/// Adapts polling frequency based on battery level via [BatteryUtils].
class SensorPoller {
  Timer? _pollTimer;
  int _intervalSeconds;
  bool _isPolling = false;

  bool get isPolling => _isPolling;
  int get intervalSeconds => _intervalSeconds;

  SensorPoller({int intervalSeconds = 5}) : _intervalSeconds = intervalSeconds;

  /// Start periodic sensor polling.
  void startPolling({required Function(SensorReading) onReading}) {
    if (_isPolling) return;
    _isPolling = true;

    _pollTimer = Timer.periodic(
      Duration(seconds: _intervalSeconds),
      (_) {
        final reading = _readSensors();
        onReading(reading);
      },
    );
  }

  /// Update the polling interval (e.g. based on battery level).
  void updateInterval(int newIntervalSeconds) {
    _intervalSeconds = newIntervalSeconds;
    if (_isPolling) {
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(
        Duration(seconds: _intervalSeconds),
        (_) {
          // Re-read and callback would be connected here
        },
      );
    }
  }

  /// Stop polling.
  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _isPolling = false;
  }

  SensorReading _readSensors() {
    // In production: read from sensors_plus
    return SensorReading(
      accelX: 0,
      accelY: 0,
      accelZ: 9.8,
      gyroX: 0,
      gyroY: 0,
      gyroZ: 0,
      timestamp: DateTime.now(),
    );
  }
}

class SensorReading {
  final double accelX;
  final double accelY;
  final double accelZ;
  final double gyroX;
  final double gyroY;
  final double gyroZ;
  final DateTime timestamp;

  const SensorReading({
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    required this.timestamp,
  });
}
