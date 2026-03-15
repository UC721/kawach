import '../../models/ai_prediction_model.dart';

/// Analyses environmental context and scene metadata.
///
/// Uses available sensor and context signals (time, location attributes,
/// light level, noise level) to classify the scene type and assess
/// environmental risk.  In a production deployment this would wrap a
/// TFLite image-classification model; the current implementation uses
/// heuristic feature scoring.
class SceneAnalyzer {
  /// Classify the current scene from available signals.
  AIPrediction analyzeScene({
    required int hour,
    double? ambientLightLux,
    double? noiseDecibels,
    bool? isIndoors,
    int nearbyPeopleEstimate = -1,
  }) {
    double riskScore = 0.0;
    final factors = <String>[];

    // ── Time of day ─────────────────────────────────────────────
    final timeRisk = _timeRisk(hour);
    riskScore += timeRisk * 0.30;
    if (timeRisk > 0.5) factors.add('high_risk_time');

    // ── Ambient light ───────────────────────────────────────────
    if (ambientLightLux != null) {
      final lightRisk = _lightRisk(ambientLightLux);
      riskScore += lightRisk * 0.25;
      if (lightRisk > 0.5) factors.add('low_light');
    }

    // ── Noise level ─────────────────────────────────────────────
    if (noiseDecibels != null) {
      final noiseRisk = _noiseRisk(noiseDecibels);
      riskScore += noiseRisk * 0.20;
      if (noiseRisk > 0.5) factors.add('quiet_environment');
    }

    // ── Crowd estimate ──────────────────────────────────────────
    if (nearbyPeopleEstimate >= 0) {
      final isolationRisk = _isolationRisk(nearbyPeopleEstimate);
      riskScore += isolationRisk * 0.25;
      if (isolationRisk > 0.5) factors.add('isolated_area');
    }

    riskScore = riskScore.clamp(0.0, 1.0);
    final sceneType = _classifySceneType(
      isIndoors: isIndoors,
      nearbyPeople: nearbyPeopleEstimate,
    );

    return AIPrediction(
      module: 'scene_analyzer',
      label: sceneType.name.toUpperCase(),
      confidence: _computeConfidence(factors.length),
      score: riskScore * 10.0,
      metadata: {
        'scene_type': sceneType.name,
        'risk_factors': factors,
        'time_risk': _timeRisk(hour),
        'ambient_light_lux': ambientLightLux,
        'noise_decibels': noiseDecibels,
        'nearby_people_estimate': nearbyPeopleEstimate,
      },
    );
  }

  // ── Scoring helpers ───────────────────────────────────────────

  double _timeRisk(int hour) {
    if (hour >= 23 || hour < 4) return 1.0;
    if (hour >= 20 || hour < 6) return 0.7;
    if (hour >= 18) return 0.3;
    return 0.0;
  }

  double _lightRisk(double lux) {
    if (lux < 10) return 1.0;   // Very dark
    if (lux < 50) return 0.7;   // Dim
    if (lux < 200) return 0.3;  // Indoor / overcast
    return 0.0;                  // Well lit
  }

  double _noiseRisk(double db) {
    // Very quiet areas can be risky (isolated).
    if (db < 30) return 0.8;
    if (db < 50) return 0.4;
    return 0.0;
  }

  double _isolationRisk(int people) {
    if (people == 0) return 1.0;
    if (people <= 2) return 0.6;
    if (people <= 5) return 0.3;
    return 0.0;
  }

  SceneType _classifySceneType({
    bool? isIndoors,
    int nearbyPeople = -1,
  }) {
    if (isIndoors == true) return SceneType.indoor;
    if (nearbyPeople > 10) return SceneType.crowded;
    if (nearbyPeople >= 0 && nearbyPeople <= 1) return SceneType.isolated;
    if (isIndoors == false) return SceneType.outdoor;
    return SceneType.unknown;
  }

  double _computeConfidence(int factorCount) {
    return (0.4 + factorCount * 0.15).clamp(0.0, 1.0);
  }
}
