import 'dart:async';

// ============================================================
// SafetyScoreService – Area safety scoring (Module 12)
// ============================================================

/// Computes a 0–10 safety score for a geographic area based on
/// historical incident data, lighting, crowd density, and time.
class SafetyScoreService {
  /// Compute safety score for a location.
  Future<AreaSafetyScore> getScore({
    required double latitude,
    required double longitude,
    DateTime? atTime,
  }) async {
    final time = atTime ?? DateTime.now();

    // Factor scores (would come from backend in production)
    final timeFactor = _timeOfDayFactor(time);
    final baseFactor = 5.0; // Neutral baseline

    final composite =
        (baseFactor * 0.5 + timeFactor * 0.5).clamp(0.0, 10.0);

    return AreaSafetyScore(
      latitude: latitude,
      longitude: longitude,
      score: composite,
      label: _scoreLabel(composite),
      computedAt: time,
      factors: {
        'time_of_day': timeFactor,
        'base': baseFactor,
      },
    );
  }

  /// Batch-compute scores for a grid of points (heatmap data).
  Future<List<AreaSafetyScore>> getHeatmapData({
    required double centerLat,
    required double centerLng,
    double radiusKm = 2.0,
    int gridResolution = 10,
  }) async {
    final scores = <AreaSafetyScore>[];
    final step = (radiusKm * 2) / gridResolution;

    for (var i = 0; i < gridResolution; i++) {
      for (var j = 0; j < gridResolution; j++) {
        final lat = (centerLat - radiusKm / 111) + (i * step / 111);
        final lng = (centerLng - radiusKm / 111) + (j * step / 111);
        final score = await getScore(latitude: lat, longitude: lng);
        scores.add(score);
      }
    }
    return scores;
  }

  double _timeOfDayFactor(DateTime time) {
    final hour = time.hour;
    if (hour >= 6 && hour < 9) return 8.0;
    if (hour >= 9 && hour < 17) return 9.0;
    if (hour >= 17 && hour < 20) return 6.0;
    if (hour >= 20 && hour < 23) return 3.0;
    return 2.0; // Late night
  }

  String _scoreLabel(double score) {
    if (score >= 8.0) return 'Very Safe';
    if (score >= 6.0) return 'Safe';
    if (score >= 4.0) return 'Moderate';
    if (score >= 2.0) return 'Caution';
    return 'Unsafe';
  }
}

class AreaSafetyScore {
  final double latitude;
  final double longitude;
  final double score;
  final String label;
  final DateTime computedAt;
  final Map<String, double> factors;

  const AreaSafetyScore({
    required this.latitude,
    required this.longitude,
    required this.score,
    required this.label,
    required this.computedAt,
    required this.factors,
  });
}
