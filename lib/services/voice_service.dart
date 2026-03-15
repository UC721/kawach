import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../models/ai_prediction_model.dart';
import '../utils/constants.dart';
import 'ai/ai_model_service.dart';

class VoiceService extends ChangeNotifier {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _isAvailable = false;
  String _lastWords = '';
  Timer? _restartTimer;
  Function()? _onPanicDetected;
  AIModelService? _aiModelService;
  AIPrediction? _latestNlpPrediction;

  bool get isListening => _isListening;
  String get lastWords => _lastWords;
  AIPrediction? get latestNlpPrediction => _latestNlpPrediction;

  Future<bool> initialize() async {
    _isAvailable = await _speech.initialize(
      onError: (err) => _handleError(err.errorMsg),
      onStatus: (status) {
        if (status == 'done' && _isListening) {
          _restartListening();
        }
      },
    );
    notifyListeners();
    return _isAvailable;
  }

  void startListening({
    required Function() onPanicDetected,
    AIModelService? aiModelService,
  }) {
    if (!_isAvailable || _isListening) return;
    _onPanicDetected = onPanicDetected;
    _aiModelService = aiModelService;
    _isListening = true;
    _listenCycle();
    notifyListeners();
  }

  void _listenCycle() {
    _speech.listen(
      onResult: (result) {
        _lastWords = result.recognizedWords.toLowerCase();
        notifyListeners();
        _checkForPanicPhrases(_lastWords);
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: false,
    );
  }

  void _restartListening() {
    if (!_isListening) return;
    _restartTimer = Timer(
        const Duration(milliseconds: 500), _listenCycle);
  }

  void _checkForPanicPhrases(String text) {
    // AI-enhanced NLP analysis when available.
    if (_aiModelService != null) {
      _latestNlpPrediction = _aiModelService!.analyzeSpeech(text);
      if (_aiModelService!.isSpeechPanic(text)) {
        _onPanicDetected?.call();
        return;
      }
    }

    // Fallback: keyword matching.
    for (final phrase in AppStrings.panicPhrases) {
      if (text.contains(phrase)) {
        _onPanicDetected?.call();
        return;
      }
    }
  }

  void stopListening() {
    _speech.stop();
    _isListening = false;
    _restartTimer?.cancel();
    _onPanicDetected = null;
    _aiModelService = null;
    notifyListeners();
  }

  void _handleError(String error) {
    if (_isListening) _restartListening();
  }

  @override
  void dispose() {
    stopListening();
    _speech.cancel();
    super.dispose();
  }
}
