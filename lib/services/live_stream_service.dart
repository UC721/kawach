import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../utils/constants.dart';

/// Manages live streaming sessions during emergencies.
/// In production, integrate with a real RTMP/WebRTC service.
class LiveStreamService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isStreaming = false;
  String? _streamUrl;
  String? _currentSessionId;

  bool get isStreaming => _isStreaming;
  String? get streamUrl => _streamUrl;

  // ── Start live stream session ────────────────────────────────
  Future<void> startStream(String userId, String emergencyId) async {
    if (_isStreaming) return;

    // In production: call your WebRTC signaling server or RTMP endpoint
    // Generate a session-specific stream URL
    _currentSessionId =
        '${userId}_${emergencyId}_${DateTime.now().millisecondsSinceEpoch}';
    _streamUrl =
        '${AppKeys.streamingServerUrl}/$_currentSessionId';

    _isStreaming = true;
    notifyListeners();

    // Store stream URL in Firestore so guardians can watch
    await _db
        .collection(FSCollection.emergencies)
        .doc(emergencyId)
        .update({
      'livestreamUrl': _streamUrl,
      'streamStartedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Stop stream ──────────────────────────────────────────────
  Future<void> stopStream() async {
    if (!_isStreaming) return;

    _isStreaming = false;
    _streamUrl = null;
    _currentSessionId = null;
    notifyListeners();
  }

  // ── Get stream URL for guardian to watch ─────────────────────
  Future<String?> getStreamUrlForEmergency(String emergencyId) async {
    final doc = await _db
        .collection(FSCollection.emergencies)
        .doc(emergencyId)
        .get();
    return doc.data()?['livestreamUrl'] as String?;
  }
}
