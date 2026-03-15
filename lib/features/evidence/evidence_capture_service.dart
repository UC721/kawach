import 'dart:async';

// ============================================================
// EvidenceCaptureService – Multi-modal evidence collection (Module 5)
// ============================================================

/// Orchestrates parallel audio, video, and photo evidence capture
/// during an active SOS.
class EvidenceCaptureService {
  bool _isCapturing = false;
  bool get isCapturing => _isCapturing;

  String? _currentSessionId;

  /// Start evidence capture for an emergency session.
  Future<void> startCapture({
    required String userId,
    required String emergencyId,
    bool audioOnly = false,
  }) async {
    if (_isCapturing) return;
    _isCapturing = true;
    _currentSessionId = emergencyId;

    // Start parallel capture streams
    unawaited(_captureAudio(userId, emergencyId));
    if (!audioOnly) {
      unawaited(_captureVideo(userId, emergencyId));
    }
  }

  Future<void> _captureAudio(String userId, String emergencyId) async {
    // Delegate to platform audio recording
    // Record in 5-minute chunks for upload
  }

  Future<void> _captureVideo(String userId, String emergencyId) async {
    // Delegate to camera service
    // Record in 1-minute chunks for upload
  }

  /// Capture a single photo for evidence.
  Future<String?> capturePhoto({
    required String userId,
    required String emergencyId,
  }) async {
    // Delegate to camera service
    return null;
  }

  /// Stop all active capture streams.
  Future<void> stopCapture() async {
    _isCapturing = false;
    _currentSessionId = null;
  }
}
