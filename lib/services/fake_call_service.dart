import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class FakeCallService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  bool _isRinging = false;
  bool _isCallActive = false;
  Timer? _autoAnswerTimer;

  bool get isRinging => _isRinging;
  bool get isCallActive => _isCallActive;

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

  Future<void> triggerFakeCall({String? callerName}) async {
    _callerName = callerName ??
        _fakeCallers[DateTime.now().millisecond % _fakeCallers.length];
    _isRinging = true;
    notifyListeners();

    // Play ringtone
    try {
      await _player.setVolume(1.0);
      await _player.play(AssetSource('audio/ringtone.mp3'));
      await _player.setReleaseMode(ReleaseMode.loop);
    } catch (_) {}

    // Auto-answer after 8 seconds if user doesn't interact
    _autoAnswerTimer = Timer(const Duration(seconds: 8), answerCall);
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
