import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../utils/constants.dart';

/// Manages live streaming sessions during emergencies.
/// In production, integrate with a real RTMP/WebRTC service.
class LiveStreamService extends ChangeNotifier {
  SupabaseClient get _db => Supabase.instance.client;

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
        .from(FSCollection.emergencies)
        .update({
      'livestreamUrl': _streamUrl,
      'streamStartedAt': DateTime.now().toIso8601String(),
    }).eq('emergencyId', emergencyId);
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
    final res = await _db
        .from(FSCollection.emergencies)
        .select('livestreamUrl')
        .eq('emergencyId', emergencyId)
        .maybeSingle();
    return res?['livestreamUrl'] as String?;
  }
}
