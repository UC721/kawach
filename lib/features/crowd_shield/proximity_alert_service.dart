import 'dart:async';
import 'dart:math';

// ============================================================
// ProximityAlertService – Crowd-sourced safety alerts (Module 8)
// ============================================================

/// Alerts nearby KAWACH users when someone triggers an SOS,
/// enabling crowd-based intervention.
class ProximityAlertService {
  final double _alertRadiusMeters;

  final StreamController<ProximityAlert> _alertStream =
      StreamController<ProximityAlert>.broadcast();
  Stream<ProximityAlert> get alerts => _alertStream.stream;

  ProximityAlertService({double alertRadiusMeters = 500.0})
      : _alertRadiusMeters = alertRadiusMeters;

  /// Check if a helper is within alert radius of the emergency.
  bool isWithinRange({
    required double helperLat,
    required double helperLng,
    required double emergencyLat,
    required double emergencyLng,
  }) {
    final distance = _haversine(
        helperLat, helperLng, emergencyLat, emergencyLng);
    return distance <= _alertRadiusMeters;
  }

  /// Create and emit a proximity alert for nearby users.
  void emitAlert({
    required String emergencyId,
    required double emergencyLat,
    required double emergencyLng,
    required double distanceMeters,
  }) {
    _alertStream.add(ProximityAlert(
      emergencyId: emergencyId,
      emergencyLat: emergencyLat,
      emergencyLng: emergencyLng,
      distanceMeters: distanceMeters,
      timestamp: DateTime.now(),
    ));
  }

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
            sin(dLng / 2) * sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRad(double d) => d * pi / 180;

  void dispose() => _alertStream.close();
}

class ProximityAlert {
  final String emergencyId;
  final double emergencyLat;
  final double emergencyLng;
  final double distanceMeters;
  final DateTime timestamp;

  const ProximityAlert({
    required this.emergencyId,
    required this.emergencyLat,
    required this.emergencyLng,
    required this.distanceMeters,
    required this.timestamp,
  });
}
