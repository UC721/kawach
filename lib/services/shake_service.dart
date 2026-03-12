import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../utils/constants.dart';

/// Custom shake detection built on sensors_plus (no separate shake package).
/// Triggers after 3 shakes within a 3-second window.
class ShakeService extends ChangeNotifier {
  StreamSubscription<AccelerometerEvent>? _sub;
  bool _isActive = false;
  int _shakeCount = 0;
  Timer? _resetTimer;
  bool _inCooldown = false;
  double _prevMagnitude = 0;

  bool get isActive => _isActive;

  void startListening({required Function() onShake}) {
    _isActive = true;
    _sub = accelerometerEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen((event) {
      final mag = sqrt(
          event.x * event.x + event.y * event.y + event.z * event.z);
      final delta = (mag - _prevMagnitude).abs();
      _prevMagnitude = mag;

      // A sharp jerk above threshold counts as one shake
      if (delta > AppThresholds.shakeThreshold && !_inCooldown) {
        _shakeCount++;
        _resetTimer?.cancel();
        _resetTimer = Timer(const Duration(seconds: 3), () {
          _shakeCount = 0;
        });
        if (_shakeCount >= 3) {
          _shakeCount = 0;
          _inCooldown = true;
          onShake();
          // 10s cooldown before re-arming
          Timer(const Duration(seconds: 10), () => _inCooldown = false);
        }
      }
    });
    notifyListeners();
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
    _resetTimer?.cancel();
    _isActive = false;
    _shakeCount = 0;
    _inCooldown = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
