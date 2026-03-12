import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:torch_light/torch_light.dart';

class SirenService extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  bool _isActive = false;
  bool _isTorchOn = false;
  Timer? _torchTimer;

  bool get isActive => _isActive;

  Future<void> startSiren() async {
    if (_isActive) return;
    _isActive = true;

    // Play loud alarm sound on loop
    try {
      await _player.setVolume(1.0);
      await _player.play(
        AssetSource('audio/emergency_siren.mp3'),
        volume: 1.0,
      );
      await _player.setReleaseMode(ReleaseMode.loop);
    } catch (_) {}

    // Flash torch rapidly
    _startTorchStrobe();
    notifyListeners();
  }

  void _startTorchStrobe() {
    _torchTimer = Timer.periodic(
      const Duration(milliseconds: 300),
      (_) async {
        try {
          if (_isTorchOn) {
            await TorchLight.disableTorch();
          } else {
            await TorchLight.enableTorch();
          }
          _isTorchOn = !_isTorchOn;
        } catch (_) {}
      },
    );
  }

  Future<void> stopSiren() async {
    _torchTimer?.cancel();
    try {
      await _player.stop();
      if (_isTorchOn) await TorchLight.disableTorch();
    } catch (_) {}
    _isTorchOn = false;
    _isActive = false;
    notifyListeners();
  }

  @override
  void dispose() {
    stopSiren();
    _player.dispose();
    super.dispose();
  }
}
