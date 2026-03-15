import 'package:flutter/material.dart';
import 'safety_score_service.dart';

// ============================================================
// HeatmapRenderer – Safety heatmap overlay (Module 12)
// ============================================================

/// Renders a safety heatmap overlay for Google Maps.
///
/// Converts [AreaSafetyScore] data into colored overlay tiles
/// where green = safe, yellow = moderate, red = unsafe.
class HeatmapRenderer {
  /// Convert a safety score (0–10) to a heatmap colour.
  static Color scoreToColor(double score) {
    if (score >= 8.0) return const Color(0x8000E676); // green
    if (score >= 6.0) return const Color(0x8066BB6A); // light green
    if (score >= 4.0) return const Color(0x80FFEB3B); // yellow
    if (score >= 2.0) return const Color(0x80FF9800); // orange
    return const Color(0x80F44336); // red
  }

  /// Generate heatmap tile data from safety scores.
  List<HeatmapTile> generateTiles(List<AreaSafetyScore> scores) {
    return scores.map((s) => HeatmapTile(
          latitude: s.latitude,
          longitude: s.longitude,
          color: scoreToColor(s.score),
          intensity: s.score / 10.0,
        )).toList();
  }
}

class HeatmapTile {
  final double latitude;
  final double longitude;
  final Color color;
  final double intensity;

  const HeatmapTile({
    required this.latitude,
    required this.longitude,
    required this.color,
    required this.intensity,
  });
}
