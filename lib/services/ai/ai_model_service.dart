import 'package:flutter/foundation.dart';

import '../../models/ai_prediction_model.dart';
import '../../models/danger_zone_model.dart';
import 'anomaly_detector.dart';
import 'behavior_analyzer.dart';
import 'nlp_analyzer.dart';
import 'route_risk_predictor.dart';
import 'scene_analyzer.dart';
import 'threat_classifier.dart';

/// Central AI inference orchestrator for all KAWACH safety modules.
///
/// Coordinates six specialised sub-models and exposes high-level methods
/// that each of the 12 safety modules can call for AI-enhanced decisions.
///
/// Sub-models:
///  • [ThreatClassifier]    – fuses multiple signals into a threat level
///  • [AnomalyDetector]     – detects motion/sensor anomalies
///  • [NlpAnalyzer]         – voice/text panic analysis
///  • [SceneAnalyzer]       – environmental context classification
///  • [RouteRiskPredictor]  – per-segment route risk scoring
///  • [BehaviorAnalyzer]    – long-term behavioural pattern analysis
class AIModelService extends ChangeNotifier {
  // Sub-models
  final ThreatClassifier threatClassifier = ThreatClassifier();
  final AnomalyDetector anomalyDetector = AnomalyDetector();
  final NlpAnalyzer nlpAnalyzer = NlpAnalyzer();
  final SceneAnalyzer sceneAnalyzer = SceneAnalyzer();
  final RouteRiskPredictor routeRiskPredictor = RouteRiskPredictor();
  final BehaviorAnalyzer behaviorAnalyzer = BehaviorAnalyzer();

  // Latest predictions per module – consumers can read these reactively.
  AIPrediction? _latestThreat;
  AIPrediction? _latestAnomaly;
  AIPrediction? _latestNlp;
  AIPrediction? _latestScene;
  AIPrediction? _latestRoute;
  AIPrediction? _latestBehavior;

  AIPrediction? get latestThreat => _latestThreat;
  AIPrediction? get latestAnomaly => _latestAnomaly;
  AIPrediction? get latestNlp => _latestNlp;
  AIPrediction? get latestScene => _latestScene;
  AIPrediction? get latestRoute => _latestRoute;
  AIPrediction? get latestBehavior => _latestBehavior;

  // ── 1. Emergency / SOS ────────────────────────────────────────
  /// Assess the threat level when an emergency is triggered or
  /// being evaluated.  Returns an overall [AIPrediction] that the
  /// emergency service uses to prioritise alerts.
  AIPrediction assessEmergencyThreat({
    double timeRisk = 0.0,
    double locationRisk = 0.0,
    double motionAnomaly = 0.0,
    double voiceIndicator = 0.0,
    double environmentRisk = 0.0,
  }) {
    _latestThreat = threatClassifier.classify(
      timeRisk: timeRisk,
      locationRisk: locationRisk,
      motionAnomaly: motionAnomaly,
      voiceIndicator: voiceIndicator,
      environmentRisk: environmentRisk,
    );
    notifyListeners();
    return _latestThreat!;
  }

  // ── 2. Evidence Vault ─────────────────────────────────────────
  /// Classify the scene context for collected evidence so that
  /// guardians and responders can prioritise review.
  AIPrediction classifyEvidenceScene({
    required int hour,
    double? ambientLightLux,
    double? noiseDecibels,
    bool? isIndoors,
    int nearbyPeopleEstimate = -1,
  }) {
    _latestScene = sceneAnalyzer.analyzeScene(
      hour: hour,
      ambientLightLux: ambientLightLux,
      noiseDecibels: noiseDecibels,
      isIndoors: isIndoors,
      nearbyPeopleEstimate: nearbyPeopleEstimate,
    );
    notifyListeners();
    return _latestScene!;
  }

  // ── 3. Guardian Network ───────────────────────────────────────
  /// Score the urgency of a guardian alert to prioritise dispatch.
  AIPrediction scoreGuardianAlertUrgency({
    required double distanceToUser,
    required double currentRiskScore,
    required int hour,
  }) {
    // Combine distance and risk into a dispatch-priority score.
    final distanceFactor = (1.0 - (distanceToUser / 5000.0)).clamp(0.0, 1.0);
    final riskFactor = (currentRiskScore / 10.0).clamp(0.0, 1.0);
    final timeFactor = _timeRiskNorm(hour);

    final urgency =
        (distanceFactor * 0.3 + riskFactor * 0.5 + timeFactor * 0.2)
            .clamp(0.0, 1.0);

    return AIPrediction(
      module: 'guardian_dispatch',
      label: urgency >= 0.7
          ? 'CRITICAL'
          : urgency >= 0.4
              ? 'HIGH'
              : 'NORMAL',
      confidence: 0.85,
      score: urgency * 10.0,
      metadata: {
        'distance_factor': distanceFactor,
        'risk_factor': riskFactor,
        'time_factor': timeFactor,
      },
    );
  }

  // ── 4. Route Safety ───────────────────────────────────────────
  /// Predict risk along a route and return segment-level details.
  AIPrediction predictRouteRisk({
    required List<Map<String, double>> waypoints,
    required List<DangerZoneModel> dangerZones,
    required int hour,
    int recentIncidentCount = 0,
  }) {
    _latestRoute = routeRiskPredictor.predictRouteRisk(
      waypoints: waypoints,
      dangerZones: dangerZones,
      hour: hour,
      recentIncidentCount: recentIncidentCount,
    );
    notifyListeners();
    return _latestRoute!;
  }

  // ── 5. Voice Detection ────────────────────────────────────────
  /// Analyse speech text for panic indicators with confidence scoring.
  AIPrediction analyzeSpeech(String text) {
    _latestNlp = nlpAnalyzer.analyzeSpeech(text);
    notifyListeners();
    return _latestNlp!;
  }

  /// Quick check suitable for real-time voice callbacks.
  bool isSpeechPanic(String text) => nlpAnalyzer.isPanic(text);

  // ── 6. Motion Detection ───────────────────────────────────────
  /// Feed a new accelerometer reading and get anomaly classification.
  AIPrediction analyzeMotion({
    required double magnitude,
    required double delta,
  }) {
    _latestAnomaly = anomalyDetector.analyze(
      magnitude: magnitude,
      delta: delta,
    );
    notifyListeners();
    return _latestAnomaly!;
  }

  // ── 7. Danger Zone ────────────────────────────────────────────
  /// Predict the severity adjustment for a danger zone based on
  /// time, recent incident trends, and environmental context.
  AIPrediction predictDangerZoneSeverity({
    required DangerZoneModel zone,
    required int hour,
    required int recentReportCount,
  }) {
    final timeFactor = _timeRiskNorm(hour);
    final incidentFactor = (recentReportCount / 10.0).clamp(0.0, 1.0);
    final baseSeverity = _severityNorm(zone.severity);

    final adjusted =
        (baseSeverity * 0.4 + incidentFactor * 0.35 + timeFactor * 0.25)
            .clamp(0.0, 1.0);

    final newSeverity = adjusted >= 0.75
        ? DangerSeverity.critical
        : adjusted >= 0.5
            ? DangerSeverity.high
            : adjusted >= 0.25
                ? DangerSeverity.medium
                : DangerSeverity.low;

    return AIPrediction(
      module: 'danger_zone_predictor',
      label: newSeverity.name.toUpperCase(),
      confidence: 0.80,
      score: adjusted * 10.0,
      metadata: {
        'original_severity': zone.severity.name,
        'adjusted_severity': newSeverity.name,
        'time_factor': timeFactor,
        'incident_factor': incidentFactor,
        'base_severity': baseSeverity,
      },
    );
  }

  // ── 8. Risk Analysis ──────────────────────────────────────────
  /// Produce a composite AI risk score combining all available latest
  /// predictions.  This replaces the purely heuristic composite score
  /// with a model-weighted approach.
  AIPrediction computeCompositeRisk({
    required double predictiveScore,
    required int nearbyZoneCount,
    required int hour,
  }) {
    final predictiveNorm = (predictiveScore / 10.0).clamp(0.0, 1.0);
    final densityNorm = (nearbyZoneCount * 0.15).clamp(0.0, 1.0);
    final timeNorm = _timeRiskNorm(hour);

    // Use dynamic weights influenced by latest sub-model signals.
    double wPredictive = 0.45;
    double wDensity = 0.30;
    double wTime = 0.25;

    // If we have fresh anomaly or NLP data, redistribute weight.
    if (_latestAnomaly != null && _latestAnomaly!.score > 5.0) {
      wPredictive = 0.35;
      wDensity = 0.25;
      wTime = 0.20;
      // Extra 0.20 for anomaly signal.
    }
    if (_latestNlp != null && _latestNlp!.label == 'PANIC') {
      wPredictive = 0.30;
    }

    double score = predictiveNorm * wPredictive +
        densityNorm * wDensity +
        timeNorm * wTime;

    // Boost from anomaly/NLP if available.
    if (_latestAnomaly != null) {
      score += (_latestAnomaly!.score / 10.0) * 0.10;
    }
    if (_latestNlp != null) {
      score += (_latestNlp!.score / 10.0) * 0.10;
    }

    score = score.clamp(0.0, 1.0);

    final level = score >= 0.7
        ? 'HIGH'
        : score >= 0.4
            ? 'MODERATE'
            : 'LOW';

    return AIPrediction(
      module: 'composite_risk',
      label: level,
      confidence: 0.85,
      score: score * 10.0,
      metadata: {
        'predictive_norm': predictiveNorm,
        'density_norm': densityNorm,
        'time_norm': timeNorm,
        'w_predictive': wPredictive,
        'w_density': wDensity,
        'w_time': wTime,
        'anomaly_boost': _latestAnomaly?.score,
        'nlp_boost': _latestNlp?.score,
      },
    );
  }

  // ── 9. Panic Detection ────────────────────────────────────────
  /// Fuse voice and motion signals to determine panic confidence.
  AIPrediction fusePanicSignals({
    required bool voiceTriggered,
    required bool motionTriggered,
    String? recognisedText,
    double? motionDelta,
  }) {
    double voiceScore = 0.0;
    double motionScore = 0.0;

    if (voiceTriggered && recognisedText != null) {
      final nlp = nlpAnalyzer.analyzeSpeech(recognisedText);
      voiceScore = nlp.score / 10.0;
    } else if (voiceTriggered) {
      voiceScore = 0.8;
    }

    if (motionTriggered && motionDelta != null) {
      motionScore = (motionDelta / 30.0).clamp(0.0, 1.0);
    } else if (motionTriggered) {
      motionScore = 0.8;
    }

    final fused = (voiceScore * 0.55 + motionScore * 0.45).clamp(0.0, 1.0);

    // Both modalities firing is very high confidence.
    final confidence = (voiceTriggered && motionTriggered)
        ? 0.95
        : (voiceTriggered || motionTriggered)
            ? 0.75
            : 0.0;

    return AIPrediction(
      module: 'panic_fusion',
      label: fused >= 0.6 ? 'PANIC_CONFIRMED' : 'POSSIBLE_PANIC',
      confidence: confidence,
      score: fused * 10.0,
      metadata: {
        'voice_triggered': voiceTriggered,
        'motion_triggered': motionTriggered,
        'voice_score': voiceScore,
        'motion_score': motionScore,
      },
    );
  }

  // ── 10. Fake Call ─────────────────────────────────────────────
  /// Determine the optimal fake-call timing based on current threat
  /// assessment.  Higher threat = shorter delay before the call.
  AIPrediction suggestFakeCallTiming({
    required double currentRiskScore,
    required int hour,
  }) {
    final riskNorm = (currentRiskScore / 10.0).clamp(0.0, 1.0);
    final timeNorm = _timeRiskNorm(hour);
    final urgency = (riskNorm * 0.7 + timeNorm * 0.3).clamp(0.0, 1.0);

    // Map urgency to a delay in seconds (lower urgency → longer delay).
    final delaySec = ((1.0 - urgency) * 15.0).round().clamp(1, 15);

    return AIPrediction(
      module: 'fake_call_timing',
      label: urgency >= 0.7 ? 'IMMEDIATE' : urgency >= 0.4 ? 'SOON' : 'NORMAL',
      confidence: 0.80,
      score: urgency * 10.0,
      metadata: {
        'suggested_delay_sec': delaySec,
        'risk_norm': riskNorm,
        'time_norm': timeNorm,
      },
    );
  }

  // ── 11. Offline Emergency ─────────────────────────────────────
  /// Provide an on-device threat assessment when the network is
  /// unavailable, relying only on sensor and time signals.
  AIPrediction assessOfflineThreat({
    required int hour,
    double? lastKnownRiskScore,
    bool motionAnomalyDetected = false,
    bool voicePanicDetected = false,
  }) {
    final timeNorm = _timeRiskNorm(hour);
    final riskNorm = ((lastKnownRiskScore ?? 0) / 10.0).clamp(0.0, 1.0);
    final motionNorm = motionAnomalyDetected ? 0.8 : 0.0;
    final voiceNorm = voicePanicDetected ? 0.9 : 0.0;

    final score = (timeNorm * 0.15 +
            riskNorm * 0.25 +
            motionNorm * 0.30 +
            voiceNorm * 0.30)
        .clamp(0.0, 1.0);

    return AIPrediction(
      module: 'offline_threat',
      label: score >= 0.6 ? 'HIGH_THREAT' : score >= 0.3 ? 'MODERATE_THREAT' : 'LOW_THREAT',
      confidence: 0.65, // Lower confidence when offline.
      score: score * 10.0,
      metadata: {
        'time_norm': timeNorm,
        'risk_norm': riskNorm,
        'motion_norm': motionNorm,
        'voice_norm': voiceNorm,
        'is_offline': true,
      },
    );
  }

  // ── 12. Live Stream ───────────────────────────────────────────
  /// Produce stream metadata analysis so guardians see a real-time
  /// threat overlay while watching the live stream.
  AIPrediction analyzeStreamContext({
    required int hour,
    double? ambientLightLux,
    double? noiseDecibels,
    double currentRiskScore = 0.0,
  }) {
    final sceneResult = sceneAnalyzer.analyzeScene(
      hour: hour,
      ambientLightLux: ambientLightLux,
      noiseDecibels: noiseDecibels,
    );

    final riskNorm = (currentRiskScore / 10.0).clamp(0.0, 1.0);
    final combinedScore =
        ((sceneResult.score / 10.0) * 0.6 + riskNorm * 0.4).clamp(0.0, 1.0);

    return AIPrediction(
      module: 'stream_analysis',
      label: combinedScore >= 0.6 ? 'HIGH_ALERT' : combinedScore >= 0.3 ? 'CAUTION' : 'STABLE',
      confidence: sceneResult.confidence,
      score: combinedScore * 10.0,
      metadata: {
        'scene_type': sceneResult.label,
        'scene_score': sceneResult.score,
        'risk_overlay': riskNorm,
        ...sceneResult.metadata,
      },
    );
  }

  // ── Behaviour tracking ────────────────────────────────────────
  /// Record a location sample for long-term behaviour analysis.
  void recordLocation({
    required double lat,
    required double lng,
    double? speed,
  }) {
    behaviorAnalyzer.addLocationSample(
      lat: lat,
      lng: lng,
      timestamp: DateTime.now(),
      speed: speed,
    );
  }

  /// Analyse current behaviour.
  AIPrediction analyzeBehavior({
    required int currentHour,
    bool isInDangerZone = false,
    double currentSpeed = 0.0,
  }) {
    _latestBehavior = behaviorAnalyzer.analyze(
      currentHour: currentHour,
      isInDangerZone: isInDangerZone,
      currentSpeed: currentSpeed,
    );
    notifyListeners();
    return _latestBehavior!;
  }

  /// Reset all sub-model state (e.g. after logout).
  void resetAll() {
    anomalyDetector.reset();
    behaviorAnalyzer.reset();
    _latestThreat = null;
    _latestAnomaly = null;
    _latestNlp = null;
    _latestScene = null;
    _latestRoute = null;
    _latestBehavior = null;
    notifyListeners();
  }

  // ── Private helpers ───────────────────────────────────────────
  double _timeRiskNorm(int hour) {
    if (hour >= 23 || hour < 4) return 1.0;
    if (hour >= 20 || hour < 6) return 0.65;
    if (hour >= 18) return 0.3;
    return 0.0;
  }

  double _severityNorm(DangerSeverity severity) {
    switch (severity) {
      case DangerSeverity.critical:
        return 1.0;
      case DangerSeverity.high:
        return 0.75;
      case DangerSeverity.medium:
        return 0.5;
      case DangerSeverity.low:
        return 0.25;
    }
  }
}
