import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../models/ai_prediction_model.dart';
import '../models/evidence_model.dart';
import '../utils/constants.dart';
import 'ai/ai_model_service.dart';

class EvidenceVaultService extends ChangeNotifier {
  final SupabaseClient _db = Supabase.instance.client;
  final _uuid = const Uuid();

  AIPrediction? _latestSceneClassification;
  AIPrediction? get latestSceneClassification => _latestSceneClassification;

  Future<void> saveEvidence({
    required String userId,
    required String emergencyId,
    String? audioUrl,
    String? videoUrl,
    Position? position,
    AIModelService? aiModelService,
  }) async {
    // AI: classify the scene for this evidence item.
    if (aiModelService != null) {
      _latestSceneClassification = aiModelService.classifyEvidenceScene(
        hour: DateTime.now().hour,
      );
    }

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

    final evidenceMap = evidence.toMap();
    // Attach AI metadata when available.
    if (_latestSceneClassification != null) {
      evidenceMap['ai_scene_type'] = _latestSceneClassification!.label;
      evidenceMap['ai_scene_confidence'] =
          _latestSceneClassification!.confidence;
    }

    await _db.from(FSCollection.evidenceVault).insert(evidenceMap);
  }

  Future<List<EvidenceModel>> getEvidence({
    required String userId,
    required String emergencyId,
  }) async {
    final res = await _db
        .from(FSCollection.evidenceVault)
        .select()
        .eq('userId', userId)
        .eq('emergencyId', emergencyId)
        .order('timestamp', ascending: true);
    return (res as List).map((d) => EvidenceModel.fromMap(d)).toList();
  }

  Stream<List<EvidenceModel>> streamEvidence({
    required String userId,
    required String emergencyId,
  }) {
    return _db
        .from(FSCollection.evidenceVault)
        .stream(primaryKey: ['evidenceId'])
        .eq('userId', userId)
        .map((docs) {
          final filtered = docs.where((d) => d['emergencyId'] == emergencyId).toList();
          filtered.sort((a, b) => (a['timestamp'] as String).compareTo(b['timestamp'] as String));
          return filtered.map((d) => EvidenceModel.fromMap(d)).toList();
        });
  }
}
