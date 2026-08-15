import 'dart:math';
import 'route_scorer.dart';

// ============================================================
// SafeRouteService – Safety-aware route planning (Module 4)
// ============================================================

/// Generates and ranks walking routes by safety score.
///
/// Considers lighting, crowd density, incident history, and
/// time-of-day to recommend the safest path.
class SafeRouteService {
  final RouteScorer _scorer;

  SafeRouteService({RouteScorer? scorer}) : _scorer = scorer ?? RouteScorer();

  /// Plan safe routes from [origin] to [destination].
  ///
  /// Returns routes sorted by safety score (highest first).
  Future<List<SafeRoute>> planRoutes({
    required LatLng origin,
    required LatLng destination,
    DateTime? departureTime,
  }) async {
    // In production, fetch candidate routes from Google Directions API
    // then score each with [RouteScorer].
    final directRoute = SafeRoute(
      waypoints: [origin, destination],
      distanceMeters: _haversine(
          origin.lat, origin.lng, destination.lat, destination.lng),
      safetyScore: 0,
      estimatedMinutes: 0,
    );

    final scored = _scorer.scoreRoute(
      directRoute,
      departureTime: departureTime ?? DateTime.now(),
    );

    return [scored];
  }

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}

class LatLng {
  final double lat;
  final double lng;
  const LatLng(this.lat, this.lng);
}

class SafeRoute {
  final List<LatLng> waypoints;
  final double distanceMeters;
  final double safetyScore;
  final int estimatedMinutes;

  const SafeRoute({
    required this.waypoints,
    required this.distanceMeters,
    required this.safetyScore,
    required this.estimatedMinutes,
  });

  SafeRoute copyWith({
    List<LatLng>? waypoints,
    double? distanceMeters,
    double? safetyScore,
    int? estimatedMinutes,
  }) {
    return SafeRoute(
      waypoints: waypoints ?? this.waypoints,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      safetyScore: safetyScore ?? this.safetyScore,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    );
  }
}
