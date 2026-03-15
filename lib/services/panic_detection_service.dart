import 'package:flutter/foundation.dart';

import '../models/ai_prediction_model.dart';
import 'ai/ai_model_service.dart';
import 'voice_service.dart';
import 'motion_detection_service.dart';

/// Orchestrates VoiceService + MotionDetectionService for auto panic detection.
class PanicDetectionService extends ChangeNotifier {
  bool _isActive = false;
  bool get isActive => _isActive;
  String? _lastTriggerReason;
  String? get lastTriggerReason => _lastTriggerReason;
  AIPrediction? _latestPanicFusion;
  AIPrediction? get latestPanicFusion => _latestPanicFusion;

  void startDetection({
    required VoiceService voiceService,
    required MotionDetectionService motionService,
    required Function(String reason) onPanicDetected,
    AIModelService? aiModelService,
  }) {
    _isActive = true;

    bool _voiceTriggered = false;
    bool _motionTriggered = false;

    // Start voice panic detection
    voiceService.startListening(
      aiModelService: aiModelService,
      onPanicDetected: () {
        _voiceTriggered = true;
        _lastTriggerReason = 'Voice panic phrase detected';

        // AI: fuse signals when available.
        if (aiModelService != null) {
          _latestPanicFusion = aiModelService.fusePanicSignals(
            voiceTriggered: true,
            motionTriggered: _motionTriggered,
            recognisedText: voiceService.lastWords,
          );
        }

        notifyListeners();
        onPanicDetected(_lastTriggerReason!);
      },
    );

    // Start motion phone-snatch detection
    motionService.startMonitoring(
      aiModelService: aiModelService,
      onSnatchDetected: () {
        _motionTriggered = true;
        _lastTriggerReason = 'Phone snatch detected';

        // AI: fuse signals when available.
        if (aiModelService != null) {
          _latestPanicFusion = aiModelService.fusePanicSignals(
            voiceTriggered: _voiceTriggered,
            motionTriggered: true,
          );
        }

        notifyListeners();
        onPanicDetected(_lastTriggerReason!);
      },
    );

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
    _latestPanicFusion = null;
    notifyListeners();
  }
}
