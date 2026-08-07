import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../utils/constants.dart';

enum AiGuardianAlertType {
  fall,
  flight,
}

class AiGuardianAlert {
  const AiGuardianAlert({
    required this.type,
    required this.message,
    required this.detectedAt,
  });

  final AiGuardianAlertType type;
  final String message;
  final DateTime detectedAt;
}

class AiGuardianService extends ChangeNotifier {
  StreamSubscription<AccelerometerEvent>? _accelerometerSub;
  StreamSubscription<GyroscopeEvent>? _gyroscopeSub;
  AiGuardianAlert? _lastAlert;
  bool _isMonitoring = false;
  bool _possibleFreeFall = false;
  DateTime? _lastTriggerAt;
  double _gyroMagnitude = 0;

  bool get isMonitoring => _isMonitoring;
  AiGuardianAlert? get lastAlert => _lastAlert;

  void startMonitoring({
    required ValueChanged<AiGuardianAlert> onAlert,
  }) {
    if (_isMonitoring) {
      return;
    }

    _isMonitoring = true;

    _gyroscopeSub = gyroscopeEventStream().listen((event) {
      _gyroMagnitude = sqrt(
        (event.x * event.x) + (event.y * event.y) + (event.z * event.z),
      );
    });

    _accelerometerSub = accelerometerEventStream().listen((event) {
      final magnitude = sqrt(
        (event.x * event.x) + (event.y * event.y) + (event.z * event.z),
      );

      if (magnitude < AppThresholds.aiGuardianFallThreshold) {
        _possibleFreeFall = true;
        return;
      }

      if (_possibleFreeFall &&
          magnitude > AppThresholds.aiGuardianImpactThreshold &&
          _gyroMagnitude > 2.5) {
        _possibleFreeFall = false;
        _emit(
          AiGuardianAlert(
            type: AiGuardianAlertType.fall,
            message: 'Possible fall impact detected',
            detectedAt: DateTime.now(),
          ),
          onAlert,
        );
        return;
      }

      if (magnitude > AppThresholds.aiGuardianSprintThreshold &&
          _gyroMagnitude > 4.0) {
        _emit(
          AiGuardianAlert(
            type: AiGuardianAlertType.flight,
            message: 'Sudden flight pattern detected',
            detectedAt: DateTime.now(),
          ),
          onAlert,
        );
      }
    });

    notifyListeners();
  }

  void stopMonitoring() {
    _accelerometerSub?.cancel();
    _gyroscopeSub?.cancel();
    _accelerometerSub = null;
    _gyroscopeSub = null;
    _isMonitoring = false;
    _possibleFreeFall = false;
    notifyListeners();
  }

  void _emit(
    AiGuardianAlert alert,
    ValueChanged<AiGuardianAlert> onAlert,
  ) {
    final now = DateTime.now();
    if (_lastTriggerAt != null &&
        now.difference(_lastTriggerAt!) < const Duration(seconds: 20)) {
      return;
    }
    _lastTriggerAt = now;
    _lastAlert = alert;
    notifyListeners();
    onAlert(alert);
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
