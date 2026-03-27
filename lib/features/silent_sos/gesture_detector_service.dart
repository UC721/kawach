import 'dart:async';
import 'power_button_detector.dart';

// ============================================================
// GestureDetectorService – Touch gesture SOS trigger (Module 7)
// ============================================================

/// Detects specific touch gestures on the screen (even with screen off
/// or from lock screen) as silent SOS triggers.
class GestureDetectorService {
  final StreamController<SilentSosTrigger> _triggerStream =
      StreamController<SilentSosTrigger>.broadcast();
  Stream<SilentSosTrigger> get triggers => _triggerStream.stream;

  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  /// Enable gesture-based SOS detection.
  void enable() => _isEnabled = true;

  /// Disable gesture-based SOS detection.
  void disable() => _isEnabled = false;

  /// Process a detected gesture pattern.
  ///
  /// Supported patterns:
  /// - "SOS" drawn on screen
  /// - Three-finger long press
  /// - Specific swipe sequence
  void onGestureDetected(String gesturePattern) {
    if (!_isEnabled) return;

    if (_isValidSosGesture(gesturePattern)) {
      _triggerStream.add(SilentSosTrigger(
        type: SilentTriggerType.gesture,
        timestamp: DateTime.now(),
        pattern: gesturePattern,
      ));
    }
  }

  bool _isValidSosGesture(String pattern) {
    const validPatterns = {
      'SOS_DRAW',
      'THREE_FINGER_PRESS',
      'SWIPE_UP_DOWN_UP',
    };
    return validPatterns.contains(pattern);
  }

  void dispose() => _triggerStream.close();
}
