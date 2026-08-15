import 'dart:async';
import 'dart:math';

// ============================================================
// AnomalyDetector – Behavioural anomaly detection (Module 2)
// ============================================================

/// Analyses sensor data streams (accelerometer, gyroscope, GPS) to
/// detect deviations from the user's normal movement baseline.
///
/// Uses a lightweight on-device model to score anomaly likelihood
/// without sending raw sensor data to the cloud.
class AnomalyDetector {
  static const double _anomalyThreshold = 0.75;

  final List<SensorSnapshot> _baseline = [];
  final int _baselineWindowSize;
  bool _isMonitoring = false;

  AnomalyDetector({int baselineWindowSize = 100})
      : _baselineWindowSize = baselineWindowSize;

  bool get isMonitoring => _isMonitoring;

  final StreamController<AnomalyEvent> _anomalyStream =
      StreamController<AnomalyEvent>.broadcast();
  Stream<AnomalyEvent> get anomalyEvents => _anomalyStream.stream;

  /// Feed a new sensor snapshot for analysis.
  void processSensorData(SensorSnapshot snapshot) {
    if (!_isMonitoring) return;

    _baseline.add(snapshot);
    if (_baseline.length > _baselineWindowSize) {
      _baseline.removeAt(0);
    }

    if (_baseline.length >= _baselineWindowSize ~/ 2) {
      final score = _computeAnomalyScore(snapshot);
      if (score >= _anomalyThreshold) {
        _anomalyStream.add(AnomalyEvent(
          score: score,
          timestamp: snapshot.timestamp,
          description: _describeAnomaly(score),
        ));
      }
    }
  }

  double _computeAnomalyScore(SensorSnapshot current) {
    if (_baseline.isEmpty) return 0.0;
    final avgMag = _baseline.map((s) => s.magnitude).reduce((a, b) => a + b) /
        _baseline.length;
    final stdDev = _standardDeviation(_baseline.map((s) => s.magnitude).toList());
    if (stdDev == 0) return 0.0;
    final zScore = (current.magnitude - avgMag).abs() / stdDev;
    return (zScore / 4.0).clamp(0.0, 1.0);
  }

  double _standardDeviation(List<double> values) {
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance =
        values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) /
            values.length;
    return sqrt(variance);
  }

  String _describeAnomaly(double score) {
    if (score > 0.9) return 'Severe movement anomaly detected';
    if (score > 0.8) return 'Significant deviation from normal pattern';
    return 'Mild behavioural anomaly detected';
  }

  void startMonitoring() => _isMonitoring = true;
  void stopMonitoring() => _isMonitoring = false;

  void dispose() {
    _anomalyStream.close();
  }
}

class SensorSnapshot {
  final double accelX;
  final double accelY;
  final double accelZ;
  final DateTime timestamp;

  const SensorSnapshot({
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.timestamp,
  });

  double get magnitude => sqrt(accelX * accelX + accelY * accelY + accelZ * accelZ);
}

class AnomalyEvent {
  final double score;
  final DateTime timestamp;
  final String description;

  const AnomalyEvent({
    required this.score,
    required this.timestamp,
    required this.description,
  });
}
