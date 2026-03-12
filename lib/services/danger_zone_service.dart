import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/danger_zone_model.dart';
import '../utils/constants.dart';

class DangerZoneService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  List<DangerZoneModel> _dangerZones = [];
  List<DangerZoneModel> get dangerZones => _dangerZones;

  bool _isInDangerZone = false;
  DangerZoneModel? _currentDangerZone;
  bool get isInDangerZone => _isInDangerZone;
  DangerZoneModel? get currentDangerZone => _currentDangerZone;

  // ── Load all danger zones ────────────────────────────────────
  Future<void> loadDangerZones() async {
    final snap = await _db.collection(FSCollection.dangerZones).get();
    _dangerZones =
        snap.docs.map((d) => DangerZoneModel.fromFirestore(d)).toList();
    notifyListeners();
  }

  // ── Real-time stream ─────────────────────────────────────────
  Stream<List<DangerZoneModel>> streamDangerZones() {
    return _db
        .collection(FSCollection.dangerZones)
        .snapshots()
        .map((snap) {
      _dangerZones =
          snap.docs.map((d) => DangerZoneModel.fromFirestore(d)).toList();
      notifyListeners();
      return _dangerZones;
    });
  }

  // ── Check if user is in a danger zone ───────────────────────
  Future<bool> checkUserInDangerZone(Position userPosition) async {
    if (_dangerZones.isEmpty) await loadDangerZones();

    for (final zone in _dangerZones) {
      final distance = Geolocator.distanceBetween(
        userPosition.latitude,
        userPosition.longitude,
        zone.lat,
        zone.lng,
      );
      if (distance <= AppThresholds.dangerZoneRadiusMeters) {
        _isInDangerZone = true;
        _currentDangerZone = zone;
        notifyListeners();
        return true;
      }
    }
    _isInDangerZone = false;
    _currentDangerZone = null;
    notifyListeners();
    return false;
  }

  // ── Aggregate & create danger zone from reports ──────────────
  Future<void> aggregateFromReports() async {
    final reportsSnap = await _db.collection(FSCollection.reports).get();
    final Map<String, List<GeoPoint>> clusters = {};

    for (final doc in reportsSnap.docs) {
      final data = doc.data();
      final GeoPoint? loc = data['location'] as GeoPoint?;
      if (loc == null) continue;

      // Simple grid-based clustering (0.005° ≈ ~500m)
      final key =
          '${(loc.latitude / 0.005).round()}_${(loc.longitude / 0.005).round()}';
      clusters.putIfAbsent(key, () => []).add(loc);
    }

    // Write aggregated danger zones
    final batch = _db.batch();
    for (final entry in clusters.entries) {
      final points = entry.value;
      final avgLat =
          points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
      final avgLng =
          points.map((p) => p.longitude).reduce((a, b) => a + b) /
              points.length;

      DangerSeverity severity;
      if (points.length >= 10) {
        severity = DangerSeverity.critical;
      } else if (points.length >= 5) {
        severity = DangerSeverity.high;
      } else if (points.length >= 2) {
        severity = DangerSeverity.medium;
      } else {
        severity = DangerSeverity.low;
      }

      final ref = _db.collection(FSCollection.dangerZones).doc(entry.key);
      batch.set(ref, {
        'lat': avgLat,
        'lng': avgLng,
        'severity': severity.name,
        'reportCount': points.length,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    await batch.commit();
    await loadDangerZones();
  }

  // ── Get nearby danger zones sorted by proximity ──────────────
  List<DangerZoneModel> getNearbyZones(
      double lat, double lng, {double radiusMeters = 1000}) {
    return _dangerZones.where((z) {
      return Geolocator.distanceBetween(lat, lng, z.lat, z.lng) <=
          radiusMeters;
    }).toList()
      ..sort((a, b) => Geolocator.distanceBetween(lat, lng, a.lat, a.lng)
          .compareTo(Geolocator.distanceBetween(lat, lng, b.lat, b.lng)));
  }
}
