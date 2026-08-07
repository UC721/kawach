import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/evidence_model.dart';
import '../utils/constants.dart';

class EvidenceVaultService extends ChangeNotifier {
  final SupabaseClient _db = Supabase.instance.client;
  final Uuid _uuid = const Uuid();

  Future<void> saveEvidence({
    required String userId,
    required String emergencyId,
    String? audioUrl,
    String? videoUrl,
    Position? position,
  }) async {
    final evidence = EvidenceModel(
      evidenceId: _uuid.v4(),
      userId: userId,
      emergencyId: emergencyId,
      audioUrl: audioUrl,
      videoUrl: videoUrl,
      lat: position?.latitude,
      lng: position?.longitude,
      timestamp: DateTime.now(),
    );

    await _db.from(FSCollection.evidenceVault).insert(evidence.toMap());
  }

  Future<List<EvidenceModel>> getEvidence({
    required String userId,
    required String emergencyId,
  }) async {
    final response = await _db
        .from(FSCollection.evidenceVault)
        .select()
        .eq('user_id', userId)
        .eq('emergency_id', emergencyId)
        .order('timestamp', ascending: true);
    return (response as List)
        .map((row) => EvidenceModel.fromMap(row as Map<String, dynamic>))
        .toList();
  }

  Stream<List<EvidenceModel>> streamEvidence({
    required String userId,
    required String emergencyId,
  }) {
    return _db
        .from(FSCollection.evidenceVault)
        .stream(primaryKey: ['evidence_id'])
        .eq('user_id', userId)
        .map((docs) {
          final filtered =
              docs.where((row) => row['emergency_id'] == emergencyId).toList()
                ..sort((left, right) {
                  final leftTime = left['timestamp'] as String? ?? '';
                  final rightTime = right['timestamp'] as String? ?? '';
                  return leftTime.compareTo(rightTime);
                });
          return filtered.map(EvidenceModel.fromMap).toList();
        });
  }
}
