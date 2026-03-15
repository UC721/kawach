import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/ai_prediction_model.dart';
import '../models/danger_zone_model.dart';
import '../utils/constants.dart';
import 'ai/ai_model_service.dart';

class DangerZoneService extends ChangeNotifier {
  final SupabaseClient _db = Supabase.instance.client;

  List<DangerZoneModel> _dangerZones = [];
  List<DangerZoneModel> get dangerZones => _dangerZones;

  bool _isInDangerZone = false;
  DangerZoneModel? _currentDangerZone;
  bool get isInDangerZone => _isInDangerZone;
  DangerZoneModel? get currentDangerZone => _currentDangerZone;

  AIPrediction? _latestZonePrediction;
  AIPrediction? get latestZonePrediction => _latestZonePrediction;

  // ── Load all danger zones ────────────────────────────────────
  Future<void> loadDangerZones() async {
    final res = await _db.from(FSCollection.dangerZones).select();
    _dangerZones =
        (res as List).map((d) => DangerZoneModel.fromMap(d)).toList();
    notifyListeners();
  }

  // ── Real-time stream ─────────────────────────────────────────
  Stream<List<DangerZoneModel>> streamDangerZones() {
    return _db
        .from(FSCollection.dangerZones)
        .stream(primaryKey: ['id'])
        .map((docs) {
      _dangerZones =
          docs.map((d) => DangerZoneModel.fromMap(d)).toList();
      notifyListeners();
      return _dangerZones;
    });
  }

  // ── Check if user is in a danger zone ───────────────────────
  Future<bool> checkUserInDangerZone(
    Position userPosition, {
    AIModelService? aiModelService,
  }) async {
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

        // AI: predict adjusted severity for this zone.
        if (aiModelService != null) {
          _latestZonePrediction = aiModelService.predictDangerZoneSeverity(
            zone: zone,
            hour: DateTime.now().hour,
            recentReportCount: zone.reportCount,
          );
        }

        notifyListeners();
        return true;
      }
    }
    _isInDangerZone = false;
    _currentDangerZone = null;
    _latestZonePrediction = null;
    notifyListeners();
    return false;
  }

  // ── Aggregate & create danger zone from reports ──────────────
  Future<void> aggregateFromReports() async {
    final res = await _db.from(FSCollection.reports).select();
    final Map<String, List<Map<String, double>>> clusters = {};

    for (final data in res as List<dynamic>) {
      final double? lat = data['latitude'] ?? data['lat'];
      final double? lng = data['longitude'] ?? data['lng'];
      if (lat == null || lng == null) continue;

      // Simple grid-based clustering (0.005° ≈ ~500m)
      final key =
          '${(lat / 0.005).round()}_${(lng / 0.005).round()}';
      clusters.putIfAbsent(key, () => []).add({'lat': lat, 'lng': lng});
    }

    // Write aggregated danger zones
    // In Supabase, batching is done by inserting/upserting a list.
    final List<Map<String, dynamic>> updates = [];
    
    for (final entry in clusters.entries) {
      final points = entry.value;
      final avgLat =
          points.map((p) => p['lat']!).reduce((a, b) => a + b) / points.length;
      final avgLng =
          points.map((p) => p['lng']!).reduce((a, b) => a + b) /
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

      updates.add({
        'id': entry.key,
        'latitude': avgLat,
        'longitude': avgLng,
        'severity': severity.name,
        'created_at': DateTime.now().toIso8601String(),
        'description': 'Aggregated Danger Zone',
      });
    }
    if (updates.isNotEmpty) {
      await _db.from(FSCollection.dangerZones).upsert(updates);
    }
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
