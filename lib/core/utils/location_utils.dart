import 'dart:math';

// ============================================================
// LocationUtils – Geospatial helper functions
// ============================================================

/// Pure-function utilities for distance, bearing, and geo-fence checks.
class LocationUtils {
  LocationUtils._();

  static const double _earthRadiusMeters = 6371000;

  /// Haversine distance between two lat/lng pairs in metres.
  static double distanceMeters(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return _earthRadiusMeters * c;
  }

  /// Initial bearing from point 1 to point 2 in degrees.
  static double bearingDegrees(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    final dLng = _toRadians(lng2 - lng1);
    final y = sin(dLng) * cos(_toRadians(lat2));
    final x = cos(_toRadians(lat1)) * sin(_toRadians(lat2)) -
        sin(_toRadians(lat1)) * cos(_toRadians(lat2)) * cos(dLng);
    return (_toDegrees(atan2(y, x)) + 360) % 360;
  }

  /// Returns `true` when [lat],[lng] is within [radiusMeters] of [centerLat],[centerLng].
  static bool isInsideRadius(
    double lat, double lng,
    double centerLat, double centerLng,
    double radiusMeters,
  ) {
    return distanceMeters(lat, lng, centerLat, centerLng) <= radiusMeters;
  }

  static double _toRadians(double deg) => deg * pi / 180;
  static double _toDegrees(double rad) => rad * 180 / pi;
}
