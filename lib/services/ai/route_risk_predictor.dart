import 'dart:math' as math;

import '../../models/ai_prediction_model.dart';
import '../../models/danger_zone_model.dart';

/// Predicts risk scores along route segments.
///
/// Combines spatial danger-zone proximity, historical incident density,
/// and time-of-day adjustments into a per-segment and aggregate risk
/// score that the route safety service uses to pick the safest path.
class RouteRiskPredictor {
  /// Predict aggregate risk for a given route defined by [waypoints].
  ///
  /// Each waypoint is a `{lat, lng}` map.  [dangerZones] provides the
  /// known hazard areas and [hour] the current time of day.
  AIPrediction predictRouteRisk({
    required List<Map<String, double>> waypoints,
    required List<DangerZoneModel> dangerZones,
    required int hour,
    int recentIncidentCount = 0,
  }) {
    if (waypoints.isEmpty) {
      return AIPrediction(
        module: 'route_risk_predictor',
        label: ThreatLevel.safe.name.toUpperCase(),
        confidence: 1.0,
        score: 0.0,
      );
    }

    double totalRisk = 0.0;
    int segmentsScored = 0;
    double maxSegmentRisk = 0.0;
    final riskySegments = <int>[];

    for (int i = 0; i < waypoints.length; i++) {
      final lat = waypoints[i]['lat']!;
      final lng = waypoints[i]['lng']!;

      double segmentRisk = 0.0;

      // ── Danger zone proximity ───────────────────────────────
      for (final zone in dangerZones) {
        final dist = _haversine(lat, lng, zone.lat, zone.lng);
        if (dist < 500) {
          final proximityFactor = 1.0 - (dist / 500.0);
          final severityWeight = _severityWeight(zone.severity);
          segmentRisk += proximityFactor * severityWeight;
        }
      }

      // ── Time penalty ────────────────────────────────────────
      segmentRisk *= _timeMultiplier(hour);

      segmentRisk = segmentRisk.clamp(0.0, 1.0);

      if (segmentRisk > 0.5) riskySegments.add(i);
      if (segmentRisk > maxSegmentRisk) maxSegmentRisk = segmentRisk;

      totalRisk += segmentRisk;
      segmentsScored++;
    }

    final avgRisk = segmentsScored > 0 ? totalRisk / segmentsScored : 0.0;

    // Incident density adjustment.
    final incidentBoost = (recentIncidentCount / 10.0).clamp(0.0, 0.3);
    final finalScore = (avgRisk + incidentBoost).clamp(0.0, 1.0);

    final level = _scoreToLevel(finalScore);

    return AIPrediction(
      module: 'route_risk_predictor',
      label: level.name.toUpperCase(),
      confidence: _computeConfidence(segmentsScored, dangerZones.length),
      score: finalScore * 10.0,
      metadata: {
        'threat_level': level.name,
        'avg_segment_risk': avgRisk,
        'max_segment_risk': maxSegmentRisk,
        'risky_segment_count': riskySegments.length,
        'risky_segment_indices': riskySegments,
        'incident_boost': incidentBoost,
        'total_segments': segmentsScored,
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────────

  double _severityWeight(DangerSeverity severity) {
    switch (severity) {
      case DangerSeverity.critical:
        return 1.0;
      case DangerSeverity.high:
        return 0.75;
      case DangerSeverity.medium:
        return 0.45;
      case DangerSeverity.low:
        return 0.2;
    }
  }

  double _timeMultiplier(int hour) {
    if (hour >= 23 || hour < 4) return 1.5;
    if (hour >= 20 || hour < 6) return 1.25;
    if (hour >= 18) return 1.1;
    return 1.0;
  }

  ThreatLevel _scoreToLevel(double score) {
    if (score >= 0.8) return ThreatLevel.critical;
    if (score >= 0.6) return ThreatLevel.high;
    if (score >= 0.4) return ThreatLevel.moderate;
    if (score >= 0.2) return ThreatLevel.low;
    return ThreatLevel.safe;
  }

  double _computeConfidence(int segments, int zoneCount) {
    final dataFactor = (segments / 20.0).clamp(0.0, 1.0);
    final zoneFactor = (zoneCount / 5.0).clamp(0.0, 1.0);
    return (0.3 + dataFactor * 0.35 + zoneFactor * 0.35).clamp(0.0, 1.0);
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742000 * math.asin(math.sqrt(a));
  }
}
