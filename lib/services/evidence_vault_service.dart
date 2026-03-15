import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../models/evidence_model.dart';
import '../utils/constants.dart';

class EvidenceVaultService extends ChangeNotifier {
  final SupabaseClient _db = Supabase.instance.client;
  final _uuid = const Uuid();

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

    await _db
        .from(FSCollection.evidenceVault)
        .insert(evidence.toMap());
  }

  Future<List<EvidenceModel>> getEvidence({
    required String userId,
    required String emergencyId,
  }) async {
    final res = await _db
        .from(FSCollection.evidenceVault)
        .select()
        .eq('user_id', userId)
        .eq('sos_alert_id', emergencyId)
        .order('created_at', ascending: true);
    return (res as List).map((d) => EvidenceModel.fromMap(d)).toList();
  }

  Stream<List<EvidenceModel>> streamEvidence({
    required String userId,
    required String emergencyId,
  }) {
    return _db
        .from(FSCollection.evidenceVault)
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((docs) {
          final filtered = docs.where((d) => d['sos_alert_id'] == emergencyId).toList();
          filtered.sort((a, b) => (a['created_at'] as String).compareTo(b['created_at'] as String));
          return filtered.map((d) => EvidenceModel.fromMap(d)).toList();
        });
  }
}
