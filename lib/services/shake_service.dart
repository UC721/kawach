import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../utils/constants.dart';

enum AnomalyType { snatch, violentShake, none }

class ShakeService extends ChangeNotifier {
  StreamSubscription<AccelerometerEvent>? _sub;
  bool _isActive = false;
  
  // Configurable sensitivity threshold
  double sensitivity = 3.0;

  // Shake detection vars
  int _shakeCount = 0;
  Timer? _resetTimer;
  bool _inCooldown = false;
  double _prevMagnitude = 0;
  
  // Snatch detection vars
  bool _potentialSnatch = false;
  Timer? _snatchVerifyTimer;

  bool get isActive => _isActive;
  Function()? _onSosTrigger;

  void startListening({required Function() onShake}) {
    _isActive = true;
    _onSosTrigger = onShake;
    
    _sub = accelerometerEventStream(
      samplingPeriod: SensorInterval.normalInterval,
    ).listen((event) {
      if (_inCooldown) return;

      final mag = sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
      final delta = (mag - _prevMagnitude).abs();
      _prevMagnitude = mag;

      // 1. Snatch Detection Logic
      // A sudden high-velocity spike (e.g. > 40)
      if (delta > 40.0 * (sensitivity / 3.0)) {
        _potentialSnatch = true;
        _snatchVerifyTimer?.cancel();
        
        // Wait a brief moment to check for 'loss of connection' or freefall/stillness
        _snatchVerifyTimer = Timer(const Duration(milliseconds: 500), () {
          if (_potentialSnatch && _prevMagnitude < 2.0) {
            // Freefall or sudden stillness after massive spike implies snatch/drop
            _triggerAnomaly(AnomalyType.snatch);
          }
          _potentialSnatch = false;
        });
      } else if (_potentialSnatch && mag > 5.0) {
        // If it continues moving normally, it wasn't a snatch
        _potentialSnatch = false;
      }

      // 2. Violent Shake Detection Logic
      // Rapid, rhythmic multi-axis acceleration spike matching violent shake
      if (delta > AppThresholds.shakeThreshold * (sensitivity / 3.0)) {
        _shakeCount++;
        _resetTimer?.cancel();
        
        // Window to complete the rhythmic shakes
        _resetTimer = Timer(const Duration(seconds: 2), () {
          _shakeCount = 0;
        });
        
        // Needs multiple rapid rhythmic spikes to trigger
        if (_shakeCount >= 4) {
          _triggerAnomaly(AnomalyType.violentShake);
        }
      }
    });
    notifyListeners();
  }

  void _triggerAnomaly(AnomalyType type) {
    _shakeCount = 0;
    _potentialSnatch = false;
    _inCooldown = true;
    
    debugPrint('--- ANOMALY DETECTED: ${type.name} ---');
    initiatePreSOSState();

    // Cooldown before re-arming
    Timer(const Duration(seconds: 10), () => _inCooldown = false);
  }

  // Internal callback function named as requested
  void initiatePreSOSState() {
    if (_onSosTrigger != null) {
      _onSosTrigger!();
    }
  }

  void stopListening() {
    _sub?.cancel();
    _sub = null;
    _resetTimer?.cancel();
    _snatchVerifyTimer?.cancel();
    _isActive = false;
    _shakeCount = 0;
    _inCooldown = false;
    _potentialSnatch = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }
}
