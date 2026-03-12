import 'dart:io';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

class CameraEvidenceService extends ChangeNotifier {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  CameraController? _controller;
  bool _isRecording = false;
  String? _currentVideoPath;

  bool get isRecording => _isRecording;

  // ── Initialize front camera silently ────────────────────────
  Future<void> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      final frontCamera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );
      _controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: true,
      );
      await _controller!.initialize();
    } catch (_) {}
  }

  // ── Start hidden video recording ─────────────────────────────
  Future<void> startVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      await initializeCamera();
    }
    if (_isRecording) return;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentVideoPath =
          '${dir.path}/emergency_video_$timestamp.mp4';
      await _controller!.startVideoRecording();
      _isRecording = true;
      notifyListeners();
    } catch (_) {}
  }

  // ── Stop and upload ──────────────────────────────────────────
  Future<String?> captureAndUpload({
    required String userId,
    required String emergencyId,
  }) async {
    await startVideoRecording();
    // Record for 30 seconds
    await Future.delayed(const Duration(seconds: 30));
    return await stopAndUpload(userId: userId, emergencyId: emergencyId);
  }

  Future<String?> stopAndUpload({
    required String userId,
    required String emergencyId,
  }) async {
    if (!_isRecording || _controller == null) return null;
    try {
      final file = await _controller!.stopVideoRecording();
      _isRecording = false;
      notifyListeners();
      return await _uploadVideo(
          filePath: file.path,
          userId: userId,
          emergencyId: emergencyId);
    } catch (_) {
      _isRecording = false;
      return null;
    }
  }

  // ── Take photo evidence ──────────────────────────────────────
  Future<String?> capturePhoto({
    required String userId,
    required String emergencyId,
  }) async {
    if (_controller == null || !_controller!.value.isInitialized) {
      await initializeCamera();
    }
    try {
      final file = await _controller!.takePicture();
      return await _uploadPhoto(
          filePath: file.path,
          userId: userId,
          emergencyId: emergencyId);
    } catch (_) {
      return null;
    }
  }

  Future<String?> _uploadVideo({
    required String filePath,
    required String userId,
    required String emergencyId,
  }) async {
    try {
      final file = File(filePath);
      final ref = _storage.ref(
          'evidence/$userId/$emergencyId/video_${DateTime.now().millisecondsSinceEpoch}.mp4');
      final task = await ref.putFile(file);
      return await task.ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  Future<String?> _uploadPhoto({
    required String filePath,
    required String userId,
    required String emergencyId,
  }) async {
    try {
      final file = File(filePath);
      final ref = _storage.ref(
          'evidence/$userId/$emergencyId/photo_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final task = await ref.putFile(file);
      return await task.ref.getDownloadURL();
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
