import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart';
import 'payload_cipher.dart';
import 'sos_queue_manager.dart';

class AudioService extends ChangeNotifier {
  AudioService({
    SosQueueManager? queueManager,
  }) : _queueManager = queueManager ?? SosQueueManager.instance;

  final AudioRecorder _recorder = AudioRecorder();
  final SosQueueManager _queueManager;
  final SupabaseStorageClient _storage = Supabase.instance.client.storage;

  bool _isRecording = false;
  String? _currentPath;

  bool get isRecording => _isRecording;

  Future<String?> startRecording() async {
    if (_isRecording) {
      return _currentPath;
    }

    if (!await _recorder.hasPermission()) {
      return null;
    }

    final directory = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _currentPath = '${directory.path}/emergency_audio_$timestamp.m4a';

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
    if (!_isRecording) {
      return null;
    }

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
    if (filePath == null) {
      return null;
    }

    return _uploadAudio(
      filePath: filePath,
      userId: userId,
      emergencyId: emergencyId,
    );
  }

  Future<String?> _uploadAudio({
    required String filePath,
    required String userId,
    required String emergencyId,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return null;
    }

    final bytes = await file.readAsBytes();
    final fileName = 'audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
    final directory = 'evidence/$userId/$emergencyId';
    final manifestPath = '$directory/$fileName.manifest.json';
    final totalChunks =
        (bytes.length / AppThresholds.evidenceChunkBytes).ceil();

    try {
      for (var offset = 0;
          offset < bytes.length;
          offset += AppThresholds.evidenceChunkBytes) {
        final end = offset + AppThresholds.evidenceChunkBytes < bytes.length
            ? offset + AppThresholds.evidenceChunkBytes
            : bytes.length;
        final chunkIndex = offset ~/ AppThresholds.evidenceChunkBytes;
        await _storage.from(FSStorage.evidenceBucket).uploadBinary(
              '$directory/$fileName.part_$chunkIndex',
              bytes.sublist(offset, end),
              fileOptions: const FileOptions(upsert: true),
            );
      }

      await _storage.from(FSStorage.evidenceBucket).uploadBinary(
            manifestPath,
            Uint8List.fromList(
              PayloadCipher.encryptObject(
                {
                  'file_name': fileName,
                  'user_id': userId,
                  'emergency_id': emergencyId,
                  'chunk_count': totalChunks,
                  'content_type': 'audio/mp4',
                },
                scope: emergencyId,
              ).codeUnits,
            ),
            fileOptions: const FileOptions(
                contentType: 'application/json', upsert: true),
          );

      return _storage.from(FSStorage.evidenceBucket).getPublicUrl(manifestPath);
    } catch (_) {
      await _queueManager.enqueueEvidenceJob({
        'kind': 'audio',
        'file_path': filePath,
        'user_id': userId,
        'emergency_id': emergencyId,
      });
      return null;
    }
  }

  @override
  void dispose() {
    _recorder.dispose();
    super.dispose();
  }
}
