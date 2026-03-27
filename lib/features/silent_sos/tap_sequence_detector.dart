import 'dart:async';
import 'power_button_detector.dart';

// ============================================================
// TapSequenceDetector – Tap pattern SOS trigger (Module 7)
// ============================================================

/// Detects Morse-code-like tap sequences on the device body
/// (via accelerometer) as silent SOS triggers.
///
/// Default trigger: "S-O-S" pattern (3 short, 3 long, 3 short taps).
class TapSequenceDetector {
  final Duration _shortTapMax;
  final Duration _longTapMin;
  final Duration _sequenceTimeout;

  final List<_TapEvent> _tapBuffer = [];
  Timer? _timeoutTimer;

  final StreamController<SilentSosTrigger> _triggerStream =
      StreamController<SilentSosTrigger>.broadcast();
  Stream<SilentSosTrigger> get triggers => _triggerStream.stream;

  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  TapSequenceDetector({
    Duration shortTapMax = const Duration(milliseconds: 200),
    Duration longTapMin = const Duration(milliseconds: 400),
    Duration sequenceTimeout = const Duration(seconds: 5),
  })  : _shortTapMax = shortTapMax,
        _longTapMin = longTapMin,
        _sequenceTimeout = sequenceTimeout;

  void enable() => _isEnabled = true;
  void disable() {
    _isEnabled = false;
    _tapBuffer.clear();
    _timeoutTimer?.cancel();
  }

  /// Record a tap event from accelerometer spike detection.
  void onTapDetected(Duration tapDuration) {
    if (!_isEnabled) return;

    final type = tapDuration < _shortTapMax
        ? _TapType.short
        : tapDuration >= _longTapMin
            ? _TapType.long
            : _TapType.medium;

    _tapBuffer.add(_TapEvent(type, DateTime.now()));

    _timeoutTimer?.cancel();
    _timeoutTimer = Timer(_sequenceTimeout, () => _tapBuffer.clear());

    _checkForSosPattern();
  }

  void _checkForSosPattern() {
    // SOS: 3 short, 3 long, 3 short
    if (_tapBuffer.length < 9) return;

    final recent = _tapBuffer.sublist(_tapBuffer.length - 9);
    final pattern = recent.map((t) => t.type).toList();

    final isSos = pattern.sublist(0, 3).every((t) => t == _TapType.short) &&
        pattern.sublist(3, 6).every((t) => t == _TapType.long) &&
        pattern.sublist(6, 9).every((t) => t == _TapType.short);

    if (isSos) {
      _triggerStream.add(SilentSosTrigger(
        type: SilentTriggerType.tapSequence,
        timestamp: DateTime.now(),
        pattern: 'SOS_MORSE',
      ));
      _tapBuffer.clear();
    }
  }

  void dispose() {
    _timeoutTimer?.cancel();
    _triggerStream.close();
  }
}

enum _TapType { short, medium, long }

class _TapEvent {
  final _TapType type;
  final DateTime timestamp;
  const _TapEvent(this.type, this.timestamp);
}
