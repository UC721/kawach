import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../models/ai_prediction_model.dart';
import '../utils/constants.dart';
import 'ai/ai_model_service.dart';

/// Detects abnormal accelerometer patterns indicating phone snatching.
class MotionDetectionService extends ChangeNotifier {
  StreamSubscription<AccelerometerEvent>? _sub;
  bool _isMonitoring = false;
  double _previousMagnitude = 0;
  Timer? _cooldown;
  bool _inCooldown = false;
  AIPrediction? _latestAnomalyPrediction;

  bool get isMonitoring => _isMonitoring;
  AIPrediction? get latestAnomalyPrediction => _latestAnomalyPrediction;

  void startMonitoring({
    required Function() onSnatchDetected,
    AIModelService? aiModelService,
  }) {
    _isMonitoring = true;
    _sub = accelerometerEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen((event) {
      final magnitude = sqrt(
        event.x * event.x +
            event.y * event.y +
            event.z * event.z,
      );

      final delta = (magnitude - _previousMagnitude).abs();
      _previousMagnitude = magnitude;

      // AI: feed the anomaly detector for continuous pattern analysis.
      if (aiModelService != null) {
        _latestAnomalyPrediction = aiModelService.analyzeMotion(
          magnitude: magnitude,
          delta: delta,
        );
      }

      if (delta > AppThresholds.snatchwatchAccelDelta && !_inCooldown) {
        _inCooldown = true;
        onSnatchDetected();
        // Cooldown to avoid duplicate triggers
        _cooldown = Timer(const Duration(seconds: 10), () {
          _inCooldown = false;
        });
      }
    });
    notifyListeners();
  }

  void stopMonitoring() {
    _sub?.cancel();
    _sub = null;
    _cooldown?.cancel();
    _isMonitoring = false;
    _inCooldown = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
