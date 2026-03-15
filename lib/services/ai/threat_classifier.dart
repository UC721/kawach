import 'dart:math';

import '../../models/ai_prediction_model.dart';

/// Classifies threat level from multiple sensor and context signals.
///
/// Uses a weighted scoring model that fuses time-of-day, location risk,
/// motion anomaly, voice indicators, and environmental signals into a
/// single [ThreatLevel] with an associated confidence score.
class ThreatClassifier {
  // Feature weights for the threat model.
  static const double _wTime = 0.15;
  static const double _wLocation = 0.25;
  static const double _wMotion = 0.20;
  static const double _wVoice = 0.20;
  static const double _wEnvironment = 0.20;

  /// Classify the current threat level given available signals.
  ///
  /// Each input is a normalised score in [0.0, 1.0].
  AIPrediction classify({
    double timeRisk = 0.0,
    double locationRisk = 0.0,
    double motionAnomaly = 0.0,
    double voiceIndicator = 0.0,
    double environmentRisk = 0.0,
  }) {
    final rawScore = (timeRisk * _wTime) +
        (locationRisk * _wLocation) +
        (motionAnomaly * _wMotion) +
        (voiceIndicator * _wVoice) +
        (environmentRisk * _wEnvironment);

    final score = rawScore.clamp(0.0, 1.0);
    final level = _scoreToLevel(score);

    // Confidence is boosted when multiple signals agree.
    final signals = [timeRisk, locationRisk, motionAnomaly, voiceIndicator, environmentRisk];
    final activeSignals = signals.where((s) => s > 0.3).length;
    final confidence = _computeConfidence(score, activeSignals);

    return AIPrediction(
      module: 'threat_classifier',
      label: level.name.toUpperCase(),
      confidence: confidence,
      score: score * 10.0, // scale to 0-10
      metadata: {
        'threat_level': level.name,
        'raw_score': score,
        'active_signals': activeSignals,
        'time_risk': timeRisk,
        'location_risk': locationRisk,
        'motion_anomaly': motionAnomaly,
        'voice_indicator': voiceIndicator,
        'environment_risk': environmentRisk,
      },
    );
  }

  ThreatLevel _scoreToLevel(double score) {
    if (score >= 0.8) return ThreatLevel.critical;
    if (score >= 0.6) return ThreatLevel.high;
    if (score >= 0.4) return ThreatLevel.moderate;
    if (score >= 0.2) return ThreatLevel.low;
    return ThreatLevel.safe;
  }

  double _computeConfidence(double score, int activeSignals) {
    // Base confidence from signal agreement.
    final agreementBoost = min(activeSignals / 5.0, 1.0) * 0.3;
    // Score extremes (very high or very low) are more confident.
    final extremityBoost = (2 * (score - 0.5).abs()) * 0.3;
    final base = 0.4;
    return (base + agreementBoost + extremityBoost).clamp(0.0, 1.0);
  }
}
