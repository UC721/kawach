import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../utils/constants.dart';
import 'payload_cipher.dart';
import 'sos_queue_manager.dart';

class CameraEvidenceService extends ChangeNotifier {
  CameraEvidenceService({
    SosQueueManager? queueManager,
  }) : _queueManager = queueManager ?? SosQueueManager.instance;

  final SupabaseStorageClient _storage = Supabase.instance.client.storage;
  final SosQueueManager _queueManager;
  CameraController? _controller;
  bool _isRecording = false;

  bool get isRecording => _isRecording;

  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: true,
      );
      await _controller!.initialize();
    } catch (error) {
      debugPrint('CameraEvidenceService.initializeCamera failed: $error');
    }
  }

  Future<void> startVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      await initializeCamera();
    }
    if (_isRecording || _controller == null) {
      return;
    }

    await _controller!.startVideoRecording();
    _isRecording = true;
    notifyListeners();
  }

  Future<String?> captureAndUpload({
    required String userId,
    required String emergencyId,
  }) async {
    await startVideoRecording();
    await Future.delayed(const Duration(seconds: 20));
    return stopAndUpload(userId: userId, emergencyId: emergencyId);
  }

  Future<String?> stopAndUpload({
    required String userId,
    required String emergencyId,
  }) async {
    if (!_isRecording || _controller == null) {
      return null;
    }

    try {
      final file = await _controller!.stopVideoRecording();
      _isRecording = false;
      notifyListeners();
      return _uploadBinaryEvidence(
        filePath: file.path,
        fileName: 'video_${DateTime.now().millisecondsSinceEpoch}.mp4',
        contentType: 'video/mp4',
        userId: userId,
        emergencyId: emergencyId,
      );
    } catch (_) {
      _isRecording = false;
      notifyListeners();
      return null;
    }
  }

  Future<String?> capturePhoto({
    required String userId,
    required String emergencyId,
  }) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      await initializeCamera();
    }
    if (_controller == null) {
      return null;
    }

    try {
      final file = await _controller!.takePicture();
      return _uploadBinaryEvidence(
        filePath: file.path,
        fileName: 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: 'image/jpeg',
        userId: userId,
        emergencyId: emergencyId,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _uploadBinaryEvidence({
    required String filePath,
    required String fileName,
    required String contentType,
    required String userId,
    required String emergencyId,
  }) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return null;
    }

    final bytes = await file.readAsBytes();
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
              fileOptions: FileOptions(contentType: contentType, upsert: true),
            );
      }

      await _storage.from(FSStorage.evidenceBucket).uploadBinary(
            manifestPath,
            Uint8List.fromList(
              PayloadCipher.encryptObject(
                {
                  'file_name': fileName,
                  'chunk_count': totalChunks,
                  'content_type': contentType,
                  'user_id': userId,
                  'emergency_id': emergencyId,
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
        'kind': contentType.startsWith('image/') ? 'image' : 'video',
        'file_path': filePath,
        'user_id': userId,
        'emergency_id': emergencyId,
      });
      return null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
