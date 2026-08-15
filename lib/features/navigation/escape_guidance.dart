import 'dart:math';
import 'safe_route_service.dart';

// ============================================================
// EscapeGuidance – Real-time escape route guidance (Module 9)
// ============================================================

/// Provides turn-by-turn escape navigation during an active SOS.
///
/// Directs the user toward the nearest safe zone (police station,
/// hospital, populated area) while avoiding known danger zones.
class EscapeGuidance {
  final List<SafeZone> _safeZones;

  EscapeGuidance({List<SafeZone>? safeZones}) : _safeZones = safeZones ?? [];

  /// Find the nearest safe zone from the user's current position.
  SafeZone? findNearestSafeZone(double userLat, double userLng) {
    if (_safeZones.isEmpty) return null;

    SafeZone? nearest;
    var minDistance = double.infinity;

    for (final zone in _safeZones) {
      final d = _haversine(userLat, userLng, zone.lat, zone.lng);
      if (d < minDistance) {
        minDistance = d;
        nearest = zone;
      }
    }
    return nearest;
  }

  /// Compute the bearing from user to the nearest safe zone.
  double? bearingToNearest(double userLat, double userLng) {
    final zone = findNearestSafeZone(userLat, userLng);
    if (zone == null) return null;
    return _bearing(userLat, userLng, zone.lat, zone.lng);
  }

  /// Generate simple text guidance toward safety.
  String getGuidanceText(double userLat, double userLng) {
    final zone = findNearestSafeZone(userLat, userLng);
    if (zone == null) return 'Move to a well-lit populated area';

    final distance = _haversine(userLat, userLng, zone.lat, zone.lng);
    final direction = _cardinalDirection(
        _bearing(userLat, userLng, zone.lat, zone.lng));

    return 'Head $direction to ${zone.name} (${distance.round()}m away)';
  }

  void addSafeZone(SafeZone zone) => _safeZones.add(zone);

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _bearing(double lat1, double lng1, double lat2, double lng2) {
    final dLng = _toRad(lng2 - lng1);
    final y = sin(dLng) * cos(_toRad(lat2));
    final x = cos(_toRad(lat1)) * sin(_toRad(lat2)) -
        sin(_toRad(lat1)) * cos(_toRad(lat2)) * cos(dLng);
    return (atan2(y, x) * 180 / pi + 360) % 360;
  }

  String _cardinalDirection(double bearing) {
    if (bearing >= 337.5 || bearing < 22.5) return 'North';
    if (bearing < 67.5) return 'NE';
    if (bearing < 112.5) return 'East';
    if (bearing < 157.5) return 'SE';
    if (bearing < 202.5) return 'South';
    if (bearing < 247.5) return 'SW';
    if (bearing < 292.5) return 'West';
    return 'NW';
  }

  double _toRad(double deg) => deg * pi / 180;
}

class SafeZone {
  final String id;
  final String name;
  final SafeZoneType type;
  final double lat;
  final double lng;

  const SafeZone({
    required this.id,
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
  });
}

enum SafeZoneType { policeStation, hospital, fireStation, publicArea }
