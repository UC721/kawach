import 'dart:math';

import '../../models/ai_prediction_model.dart';

/// Detects anomalous patterns in sensor data streams.
///
/// Maintains a sliding window of recent readings and uses statistical
/// deviation analysis to detect sudden changes characteristic of
/// phone snatching, falls, or erratic movement.
class AnomalyDetector {
  final int _windowSize;
  final List<double> _magnitudeWindow = [];
  final List<double> _deltaWindow = [];

  AnomalyDetector({int windowSize = 50}) : _windowSize = windowSize;

  /// Analyse a new accelerometer magnitude reading.
  ///
  /// Returns an [AIPrediction] describing whether the latest reading
  /// constitutes an anomaly and what kind of motion pattern is detected.
  AIPrediction analyze({
    required double magnitude,
    required double delta,
  }) {
    _magnitudeWindow.add(magnitude);
    _deltaWindow.add(delta);

    if (_magnitudeWindow.length > _windowSize) {
      _magnitudeWindow.removeAt(0);
      _deltaWindow.removeAt(0);
    }

    // Need minimum data points before meaningful classification.
    if (_magnitudeWindow.length < 5) {
      return AIPrediction(
        module: 'anomaly_detector',
        label: BehaviorPattern.unknown.name.toUpperCase(),
        confidence: 0.0,
        score: 0.0,
        metadata: {'status': 'collecting_data'},
      );
    }

    final meanDelta = _mean(_deltaWindow);
    final stdDelta = _stddev(_deltaWindow);
    final meanMag = _mean(_magnitudeWindow);

    // Z-score of the latest delta relative to the window.
    final zScore = stdDelta > 0 ? (delta - meanDelta) / stdDelta : 0.0;

    final pattern = _classifyPattern(
      delta: delta,
      zScore: zScore,
      meanMagnitude: meanMag,
      stdDelta: stdDelta,
    );

    final anomalyScore = _computeAnomalyScore(zScore, delta, stdDelta);
    final confidence = _computeConfidence(zScore, _magnitudeWindow.length);

    return AIPrediction(
      module: 'anomaly_detector',
      label: pattern.name.toUpperCase(),
      confidence: confidence,
      score: anomalyScore * 10.0,
      metadata: {
        'pattern': pattern.name,
        'z_score': zScore,
        'mean_delta': meanDelta,
        'std_delta': stdDelta,
        'mean_magnitude': meanMag,
        'window_size': _magnitudeWindow.length,
      },
    );
  }

  BehaviorPattern _classifyPattern({
    required double delta,
    required double zScore,
    required double meanMagnitude,
    required double stdDelta,
  }) {
    // Sudden large jerk → snatch/fleeing
    if (zScore > 3.0 && delta > 15.0) return BehaviorPattern.fleeing;
    // Consistently high variance → erratic movement
    if (stdDelta > 8.0) return BehaviorPattern.erratic;
    // Very low magnitude and variance → stationary
    if (meanMagnitude < 10.5 && stdDelta < 1.0) return BehaviorPattern.stationary;
    // Periodic moderate spikes → possible followed pattern
    if (_detectPeriodicSpikes()) return BehaviorPattern.followedPattern;
    return BehaviorPattern.normal;
  }

  double _computeAnomalyScore(double zScore, double delta, double stdDelta) {
    // Blend z-score and raw delta into 0-1 range.
    final zComponent = (zScore.abs() / 5.0).clamp(0.0, 1.0);
    final deltaComponent = (delta / 30.0).clamp(0.0, 1.0);
    return (zComponent * 0.6 + deltaComponent * 0.4).clamp(0.0, 1.0);
  }

  double _computeConfidence(double zScore, int windowLength) {
    // Confidence increases with more data and higher z-scores.
    final dataFactor = (windowLength / _windowSize).clamp(0.0, 1.0);
    final signalFactor = (zScore.abs() / 4.0).clamp(0.0, 1.0);
    return (dataFactor * 0.4 + signalFactor * 0.6).clamp(0.0, 1.0);
  }

  bool _detectPeriodicSpikes() {
    if (_deltaWindow.length < 20) return false;
    final threshold = _mean(_deltaWindow) + _stddev(_deltaWindow) * 1.5;
    int spikeCount = 0;
    for (final d in _deltaWindow) {
      if (d > threshold) spikeCount++;
    }
    // Periodic if 15-40 % of readings are spikes.
    final ratio = spikeCount / _deltaWindow.length;
    return ratio > 0.15 && ratio < 0.40;
  }

  void reset() {
    _magnitudeWindow.clear();
    _deltaWindow.clear();
  }

  // ── Statistics helpers ─────────────────────────────────────────
  double _mean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _stddev(List<double> values) {
    if (values.length < 2) return 0.0;
    final m = _mean(values);
    final variance = values.map((v) => (v - m) * (v - m)).reduce((a, b) => a + b) / values.length;
    return sqrt(variance);
  }
}
