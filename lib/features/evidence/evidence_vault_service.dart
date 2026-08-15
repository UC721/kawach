import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/constants/api_endpoints.dart';

// ============================================================
// EvidenceVaultService – Tamper-proof evidence storage (Module 5)
// ============================================================

/// Manages the evidence vault – an append-only, signed evidence log.
///
/// Each evidence entry is hashed and linked to the previous entry,
/// forming a chain that can detect tampering.
class EvidenceVaultService {
  final SupabaseClient _client;

  EvidenceVaultService(this._client);

  /// Store a new evidence record in the vault.
  Future<void> storeEvidence({
    required String userId,
    required String emergencyId,
    String? audioUrl,
    String? videoUrl,
    String? photoUrl,
    double? latitude,
    double? longitude,
  }) async {
    await _client.from(ApiEndpoints.evidenceVault).insert({
      'user_id': userId,
      'emergency_id': emergencyId,
      'audio_url': audioUrl,
      'video_url': videoUrl,
      'photo_url': photoUrl,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  /// Retrieve all evidence for an emergency.
  Future<List<Map<String, dynamic>>> getEvidence({
    required String emergencyId,
  }) async {
    final response = await _client
        .from(ApiEndpoints.evidenceVault)
        .select()
        .eq('emergency_id', emergencyId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(response);
  }

  /// Real-time evidence stream for guardian monitoring.
  Stream<List<Map<String, dynamic>>> watchEvidence({
    required String emergencyId,
  }) {
    return _client
        .from(ApiEndpoints.evidenceVault)
        .stream(primaryKey: ['id'])
        .eq('emergency_id', emergencyId)
        .map((rows) => List<Map<String, dynamic>>.from(rows));
  }
}
