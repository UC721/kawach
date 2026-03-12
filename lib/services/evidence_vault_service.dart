import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../models/evidence_model.dart';
import '../utils/constants.dart';

class EvidenceVaultService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  Future<void> saveEvidence({
    required String userId,
    required String emergencyId,
    String? audioUrl,
    String? videoUrl,
    Position? position,
  }) async {
    GeoPoint? geoPoint;
    if (position != null) {
      geoPoint = GeoPoint(position.latitude, position.longitude);
    }

    final evidence = EvidenceModel(
      evidenceId: _uuid.v4(),
      userId: userId,
      emergencyId: emergencyId,
      audioUrl: audioUrl,
      videoUrl: videoUrl,
      location: geoPoint,
      timestamp: DateTime.now(),
    );

    await _db
        .collection(FSCollection.evidenceVault)
        .doc(evidence.evidenceId)
        .set(evidence.toMap());
  }

  Future<List<EvidenceModel>> getEvidence({
    required String userId,
    required String emergencyId,
  }) async {
    final snap = await _db
        .collection(FSCollection.evidenceVault)
        .where('userId', isEqualTo: userId)
        .where('emergencyId', isEqualTo: emergencyId)
        .orderBy('timestamp', descending: false)
        .get();
    return snap.docs.map((d) => EvidenceModel.fromFirestore(d)).toList();
  }

  Stream<List<EvidenceModel>> streamEvidence({
    required String userId,
    required String emergencyId,
  }) {
    return _db
        .collection(FSCollection.evidenceVault)
        .where('userId', isEqualTo: userId)
        .where('emergencyId', isEqualTo: emergencyId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => EvidenceModel.fromFirestore(d)).toList());
  }
}
