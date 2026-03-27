import 'dart:async';
import 'dart:typed_data';

// ============================================================
// AudioThreatService – Audio-based threat detection (Module 2)
// ============================================================

/// Processes audio streams to detect threat indicators such as
/// screams, aggressive speech, glass breaking, or distress keywords.
///
/// Uses a TFLite model (`audio_threat.tflite`) for on-device inference.
class AudioThreatService {
  static const String modelAsset = 'assets/models/audio_threat.tflite';
  static const double _threatThreshold = 0.7;

  bool _isListening = false;
  bool get isListening => _isListening;

  final StreamController<AudioThreatEvent> _threatStream =
      StreamController<AudioThreatEvent>.broadcast();
  Stream<AudioThreatEvent> get threatEvents => _threatStream.stream;

  /// Start continuous audio monitoring.
  Future<void> startListening() async {
    if (_isListening) return;
    _isListening = true;
    // In production: initialize TFLite interpreter and audio stream
  }

  /// Process a raw audio frame and classify threat level.
  ///
  /// [audioFrame] should be a PCM-encoded audio chunk.
  Future<AudioThreatEvent?> processAudioFrame(Float32List audioFrame) async {
    if (!_isListening) return null;

    // TFLite inference would happen here
    // final output = interpreter.run(audioFrame);
    final classification = _classifyPlaceholder(audioFrame);

    if (classification.confidence >= _threatThreshold) {
      _threatStream.add(classification);
      return classification;
    }
    return null;
  }

  /// Stop audio monitoring.
  Future<void> stopListening() async {
    _isListening = false;
  }

  // Placeholder classification until TFLite model is integrated
  AudioThreatEvent _classifyPlaceholder(Float32List frame) {
    // Compute simple energy level as a proxy
    var energy = 0.0;
    for (final sample in frame) {
      energy += sample * sample;
    }
    energy = energy / frame.length;

    AudioThreatType type;
    if (energy > 0.8) {
      type = AudioThreatType.scream;
    } else if (energy > 0.5) {
      type = AudioThreatType.aggressiveSpeech;
    } else {
      type = AudioThreatType.ambient;
    }

    return AudioThreatEvent(
      type: type,
      confidence: energy.clamp(0.0, 1.0),
      timestamp: DateTime.now(),
    );
  }

  void dispose() {
    _threatStream.close();
  }
}

enum AudioThreatType { ambient, aggressiveSpeech, scream, glassBreak, gunshot }

class AudioThreatEvent {
  final AudioThreatType type;
  final double confidence;
  final DateTime timestamp;

  const AudioThreatEvent({
    required this.type,
    required this.confidence,
    required this.timestamp,
  });
}
