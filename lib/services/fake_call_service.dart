import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

import '../models/ai_prediction_model.dart';
import 'ai/ai_model_service.dart';

class FakeCallService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  bool _isRinging = false;
  bool _isCallActive = false;
  Timer? _autoAnswerTimer;
  AIPrediction? _latestTimingSuggestion;

  bool get isRinging => _isRinging;
  bool get isCallActive => _isCallActive;
  AIPrediction? get latestTimingSuggestion => _latestTimingSuggestion;

  // Fake contact names for the simulated call
  final List<String> _fakeCallers = [
    'Mom',
    'Dad',
    'Sister',
    'Boss',
    'Friend',
    'Police',
  ];

  String _callerName = 'Mom';
  String get callerName => _callerName;

  Future<void> triggerFakeCall({
    String? callerName,
    AIModelService? aiModelService,
    double currentRiskScore = 0.0,
  }) async {
    _callerName = callerName ??
        _fakeCallers[DateTime.now().millisecond % _fakeCallers.length];
    _isRinging = true;
    notifyListeners();

    // AI: determine optimal auto-answer delay based on threat assessment.
    int autoAnswerDelay = 8;
    if (aiModelService != null) {
      _latestTimingSuggestion = aiModelService.suggestFakeCallTiming(
        currentRiskScore: currentRiskScore,
        hour: DateTime.now().hour,
      );
      autoAnswerDelay =
          (_latestTimingSuggestion!.metadata['suggested_delay_sec'] as int?) ??
              8;
    }

    // Play ringtone
    try {
      await _player.setVolume(1.0);
      await _player.play(AssetSource('audio/ringtone.mp3'));
      await _player.setReleaseMode(ReleaseMode.loop);
    } catch (_) {}

    // Auto-answer after AI-determined delay if user doesn't interact
    _autoAnswerTimer =
        Timer(Duration(seconds: autoAnswerDelay), answerCall);
  }

  void answerCall() {
    _autoAnswerTimer?.cancel();
    _isRinging = false;
    _isCallActive = true;
    notifyListeners();
    try {
      _player.stop();
    } catch (_) {}
  }

  Future<void> endCall() async {
    _autoAnswerTimer?.cancel();
    _isRinging = false;
    _isCallActive = false;
    try {
      await _player.stop();
    } catch (_) {}
    notifyListeners();
  }

  @override
  void dispose() {
    endCall();
    _player.dispose();
    super.dispose();
  }
}
