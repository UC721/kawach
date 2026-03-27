// ============================================================
// RouteScorer – Multi-factor route safety scoring (Module 4)
// ============================================================

import 'safe_route_service.dart';

/// Scores a route on a 0–10 scale based on safety factors.
class RouteScorer {
  /// Compute a composite safety score for [route].
  SafeRoute scoreRoute(SafeRoute route, {required DateTime departureTime}) {
    final timeScore = _timeOfDayScore(departureTime);
    final distanceScore = _distancePenalty(route.distanceMeters);

    // Weighted composite (add more signals as data becomes available)
    final composite = (timeScore * 0.4 + distanceScore * 0.3 + 5.0 * 0.3)
        .clamp(0.0, 10.0);

    final estimatedMinutes = (route.distanceMeters / 80).round(); // ~5 km/h

    return route.copyWith(
      safetyScore: composite,
      estimatedMinutes: estimatedMinutes,
    );
  }

  /// Higher score during daylight hours.
  double _timeOfDayScore(DateTime time) {
    final hour = time.hour;
    if (hour >= 7 && hour < 18) return 8.0;
    if (hour >= 18 && hour < 21) return 5.0;
    return 2.0; // Late night
  }

  /// Penalize longer routes (more exposure time).
  double _distancePenalty(double meters) {
    if (meters < 500) return 9.0;
    if (meters < 1500) return 7.0;
    if (meters < 5000) return 5.0;
    return 3.0;
  }
}
