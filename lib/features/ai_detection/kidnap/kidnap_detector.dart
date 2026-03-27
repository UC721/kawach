import 'dart:async';
import '../behavioral/movement_analyzer.dart';
import '../behavioral/anomaly_detector.dart';
import '../audio/audio_threat_service.dart';

// ============================================================
// KidnapDetector – Multi-signal kidnap detection (Module 10)
// ============================================================

/// Fuses signals from movement, audio, and behavioural analysis to
/// detect potential kidnapping or abduction scenarios.
///
/// A high composite score triggers an automatic silent SOS.
class KidnapDetector {
  final MovementAnalyzer _movementAnalyzer;
  final AnomalyDetector _anomalyDetector;
  final AudioThreatService _audioService;

  static const double _kidnapThreshold = 0.8;

  final StreamController<KidnapAlert> _alertStream =
      StreamController<KidnapAlert>.broadcast();
  Stream<KidnapAlert> get alerts => _alertStream.stream;

  bool _isMonitoring = false;
  bool get isMonitoring => _isMonitoring;

  KidnapDetector({
    required MovementAnalyzer movementAnalyzer,
    required AnomalyDetector anomalyDetector,
    required AudioThreatService audioService,
  })  : _movementAnalyzer = movementAnalyzer,
        _anomalyDetector = anomalyDetector,
        _audioService = audioService;

  /// Start multi-signal monitoring.
  void startMonitoring() {
    _isMonitoring = true;
    _anomalyDetector.startMonitoring();
  }

  /// Evaluate kidnap likelihood from current signal state.
  ///
  /// Call this periodically (e.g. every 5 seconds) with latest data.
  KidnapAssessment evaluate({
    double? anomalyScore,
    AudioThreatType? latestAudioThreat,
    double? audioConfidence,
  }) {
    if (!_isMonitoring) {
      return const KidnapAssessment(score: 0, signals: []);
    }

    final signals = <String>[];
    var compositeScore = 0.0;
    var weightSum = 0.0;

    // Signal 1: Sudden movement change (weight 0.3)
    if (_movementAnalyzer.detectSuddenStop()) {
      compositeScore += 0.3 * 0.9;
      signals.add('Sudden stop detected');
    } else if (_movementAnalyzer.detectSuddenAcceleration()) {
      compositeScore += 0.3 * 0.8;
      signals.add('Sudden acceleration detected');
    }
    weightSum += 0.3;

    // Signal 2: Behavioural anomaly (weight 0.35)
    if (anomalyScore != null && anomalyScore > 0.7) {
      compositeScore += 0.35 * anomalyScore;
      signals.add('Movement anomaly: ${(anomalyScore * 100).toInt()}%');
    }
    weightSum += 0.35;

    // Signal 3: Audio threat (weight 0.35)
    if (latestAudioThreat != null &&
        latestAudioThreat != AudioThreatType.ambient) {
      final threatScore = audioConfidence ?? 0.5;
      compositeScore += 0.35 * threatScore;
      signals.add('Audio threat: ${latestAudioThreat.name}');
    }
    weightSum += 0.35;

    final normalised =
        weightSum > 0 ? compositeScore / weightSum : 0.0;

    final assessment = KidnapAssessment(
      score: normalised,
      signals: signals,
    );

    if (normalised >= _kidnapThreshold) {
      _alertStream.add(KidnapAlert(
        assessment: assessment,
        timestamp: DateTime.now(),
      ));
    }

    return assessment;
  }

  void stopMonitoring() {
    _isMonitoring = false;
    _anomalyDetector.stopMonitoring();
  }

  void dispose() {
    _alertStream.close();
  }
}

class KidnapAssessment {
  final double score;
  final List<String> signals;

  const KidnapAssessment({required this.score, required this.signals});
}

class KidnapAlert {
  final KidnapAssessment assessment;
  final DateTime timestamp;

  const KidnapAlert({required this.assessment, required this.timestamp});
}
