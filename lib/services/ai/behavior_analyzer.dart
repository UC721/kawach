import '../../models/ai_prediction_model.dart';

/// Analyses user behavioral patterns over time.
///
/// Tracks location history, motion cadence, and interaction patterns
/// to detect deviations from normal behaviour that may indicate a
/// safety concern (e.g. user suddenly stationary in an unusual area,
/// or moving erratically late at night).
class BehaviorAnalyzer {
  final List<_LocationSample> _locationHistory = [];
  final int _maxHistory;

  BehaviorAnalyzer({int maxHistory = 100}) : _maxHistory = maxHistory;

  /// Record a new location sample.
  void addLocationSample({
    required double lat,
    required double lng,
    required DateTime timestamp,
    double? speed,
  }) {
    _locationHistory.add(_LocationSample(
      lat: lat,
      lng: lng,
      timestamp: timestamp,
      speed: speed ?? 0.0,
    ));
    if (_locationHistory.length > _maxHistory) {
      _locationHistory.removeAt(0);
    }
  }

  /// Analyse current behaviour and return a prediction.
  AIPrediction analyze({
    required int currentHour,
    bool isInDangerZone = false,
    double currentSpeed = 0.0,
  }) {
    if (_locationHistory.length < 3) {
      return AIPrediction(
        module: 'behavior_analyzer',
        label: BehaviorPattern.unknown.name.toUpperCase(),
        confidence: 0.0,
        score: 0.0,
        metadata: {'status': 'insufficient_data'},
      );
    }

    final pattern = _classifyPattern(currentSpeed);
    final riskScore = _assessRisk(
      pattern: pattern,
      currentHour: currentHour,
      isInDangerZone: isInDangerZone,
      currentSpeed: currentSpeed,
    );

    return AIPrediction(
      module: 'behavior_analyzer',
      label: pattern.name.toUpperCase(),
      confidence: _computeConfidence(),
      score: riskScore * 10.0,
      metadata: {
        'pattern': pattern.name,
        'sample_count': _locationHistory.length,
        'avg_speed': _averageSpeed(),
        'speed_variance': _speedVariance(),
        'is_in_danger_zone': isInDangerZone,
      },
    );
  }

  BehaviorPattern _classifyPattern(double currentSpeed) {
    final avgSpeed = _averageSpeed();
    final speedVar = _speedVariance();

    // Stationary if very low speed.
    if (avgSpeed < 0.5 && currentSpeed < 0.5) {
      return BehaviorPattern.stationary;
    }

    // Erratic if high speed variance.
    if (speedVar > 10.0) return BehaviorPattern.erratic;

    // Fleeing if sudden high speed.
    if (currentSpeed > avgSpeed * 3.0 && currentSpeed > 3.0) {
      return BehaviorPattern.fleeing;
    }

    return BehaviorPattern.normal;
  }

  double _assessRisk({
    required BehaviorPattern pattern,
    required int currentHour,
    required bool isInDangerZone,
    required double currentSpeed,
  }) {
    double risk = 0.0;

    // Pattern-based risk.
    switch (pattern) {
      case BehaviorPattern.erratic:
        risk += 0.3;
        break;
      case BehaviorPattern.fleeing:
        risk += 0.4;
        break;
      case BehaviorPattern.stationary:
        risk += 0.15;
        break;
      case BehaviorPattern.followedPattern:
        risk += 0.35;
        break;
      default:
        break;
    }

    // Time penalty.
    if (currentHour >= 22 || currentHour < 5) {
      risk += 0.25;
    } else if (currentHour >= 19) {
      risk += 0.1;
    }

    // Danger zone amplifier.
    if (isInDangerZone) risk += 0.2;

    return risk.clamp(0.0, 1.0);
  }

  double _averageSpeed() {
    if (_locationHistory.isEmpty) return 0.0;
    return _locationHistory.map((s) => s.speed).reduce((a, b) => a + b) /
        _locationHistory.length;
  }

  double _speedVariance() {
    if (_locationHistory.length < 2) return 0.0;
    final avg = _averageSpeed();
    final sumSq = _locationHistory
        .map((s) => (s.speed - avg) * (s.speed - avg))
        .reduce((a, b) => a + b);
    return sumSq / _locationHistory.length;
  }

  double _computeConfidence() {
    return (_locationHistory.length / _maxHistory).clamp(0.3, 1.0);
  }

  void reset() => _locationHistory.clear();
}

class _LocationSample {
  final double lat;
  final double lng;
  final DateTime timestamp;
  final double speed;

  _LocationSample({
    required this.lat,
    required this.lng,
    required this.timestamp,
    required this.speed,
  });
}
