import 'package:flutter/foundation.dart';

import 'voice_service.dart';
import 'motion_detection_service.dart';

/// Orchestrates VoiceService + MotionDetectionService for auto panic detection.
class PanicDetectionService extends ChangeNotifier {
  bool _isActive = false;
  bool get isActive => _isActive;
  String? _lastTriggerReason;
  String? get lastTriggerReason => _lastTriggerReason;

  void startDetection({
    required VoiceService voiceService,
    required MotionDetectionService motionService,
    required Function(String reason) onPanicDetected,
  }) {
    _isActive = true;

    // Start voice panic detection
    voiceService.startListening(onPanicDetected: () {
      _lastTriggerReason = 'Voice panic phrase detected';
      notifyListeners();
      onPanicDetected(_lastTriggerReason!);
    });

    // Start motion phone-snatch detection
    motionService.startMonitoring(onSnatchDetected: () {
      _lastTriggerReason = 'Phone snatch detected';
      notifyListeners();
      onPanicDetected(_lastTriggerReason!);
    });

    notifyListeners();
  }

  void stopDetection({
    required VoiceService voiceService,
    required MotionDetectionService motionService,
  }) {
    voiceService.stopListening();
    motionService.stopMonitoring();
    _isActive = false;
    _lastTriggerReason = null;
    notifyListeners();
  }
}
