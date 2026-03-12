import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioService extends ChangeNotifier {
  final AudioRecorder _recorder = AudioRecorder();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  bool _isRecording = false;
  String? _currentPath;

  bool get isRecording => _isRecording;

  Future<String?> startRecording() async {
    if (_isRecording) return _currentPath;

    if (!await _recorder.hasPermission()) return null;

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _currentPath = '${dir.path}/emergency_audio_$timestamp.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _currentPath!,
    );

    _isRecording = true;
    notifyListeners();
    return _currentPath;
  }

  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    final path = await _recorder.stop();
    _isRecording = false;
    notifyListeners();
    return path;
  }

  Future<String?> stopAndUpload({
    required String userId,
    required String emergencyId,
  }) async {
    final filePath = await stopRecording();
    if (filePath == null) return null;
    return await _uploadAudio(
        filePath: filePath,
        userId: userId,
        emergencyId: emergencyId);
  }

  Future<String?> _uploadAudio({
    required String filePath,
    required String userId,
    required String emergencyId,
  }) async {
    try {
      final file = File(filePath);
      final ref = _storage.ref(
          'evidence/$userId/$emergencyId/audio_${DateTime.now().millisecondsSinceEpoch}.m4a');
      final task = await ref.putFile(file);
      return await task.ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }
}
