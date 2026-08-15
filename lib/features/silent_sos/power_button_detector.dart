import 'dart:async';

// ============================================================
// PowerButtonDetector – Hardware button SOS trigger (Module 7)
// ============================================================

/// Detects rapid power-button press sequences (e.g. 5× in 3 seconds)
/// as a silent SOS trigger.
///
/// Listens for screen-on/off lifecycle events to infer button presses.
class PowerButtonDetector {
  final int _requiredPresses;
  final Duration _timeWindow;

  final List<DateTime> _pressTimestamps = [];
  final StreamController<SilentSosTrigger> _triggerStream =
      StreamController<SilentSosTrigger>.broadcast();

  Stream<SilentSosTrigger> get triggers => _triggerStream.stream;

  PowerButtonDetector({
    int requiredPresses = 5,
    Duration timeWindow = const Duration(seconds: 3),
  })  : _requiredPresses = requiredPresses,
        _timeWindow = timeWindow;

  /// Call this when a power button press (screen toggle) is detected.
  void onPowerButtonPress() {
    final now = DateTime.now();
    _pressTimestamps.add(now);

    // Remove presses outside the time window
    final cutoff = now.subtract(_timeWindow);
    _pressTimestamps.removeWhere((t) => t.isBefore(cutoff));

    if (_pressTimestamps.length >= _requiredPresses) {
      _triggerStream.add(SilentSosTrigger(
        type: SilentTriggerType.powerButton,
        timestamp: now,
        pressCount: _pressTimestamps.length,
      ));
      _pressTimestamps.clear();
    }
  }

  void reset() => _pressTimestamps.clear();

  void dispose() => _triggerStream.close();
}

class SilentSosTrigger {
  final SilentTriggerType type;
  final DateTime timestamp;
  final int? pressCount;
  final String? pattern;

  const SilentSosTrigger({
    required this.type,
    required this.timestamp,
    this.pressCount,
    this.pattern,
  });
}

enum SilentTriggerType { powerButton, gesture, tapSequence }
