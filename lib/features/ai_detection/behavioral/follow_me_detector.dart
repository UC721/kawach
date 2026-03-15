import 'dart:math';

// ============================================================
// FollowMeDetector – Stalker / follow detection (Module 6)
// ============================================================

/// Detects whether the same device or entity appears to be following
/// the user across multiple location checkpoints.
///
/// Uses spatial proximity correlation over time windows.
class FollowMeDetector {
  final double _proximityThresholdMeters;
  final int _minCorrelationPoints;
  final Duration _timeWindow;

  final List<_ProximityRecord> _records = [];
  final Map<String, int> _entityCorrelation = {};

  FollowMeDetector({
    double proximityThresholdMeters = 50.0,
    int minCorrelationPoints = 3,
    Duration timeWindow = const Duration(minutes: 15),
  })  : _proximityThresholdMeters = proximityThresholdMeters,
        _minCorrelationPoints = minCorrelationPoints,
        _timeWindow = timeWindow;

  /// Record a nearby entity observation at the user's current location.
  void recordNearbyEntity({
    required String entityId,
    required double userLat,
    required double userLng,
    required double entityLat,
    required double entityLng,
  }) {
    _evictOldRecords();

    final distance = _haversine(userLat, userLng, entityLat, entityLng);
    if (distance <= _proximityThresholdMeters) {
      _records.add(_ProximityRecord(
        entityId: entityId,
        distance: distance,
        timestamp: DateTime.now(),
      ));
      _entityCorrelation[entityId] =
          (_entityCorrelation[entityId] ?? 0) + 1;
    }
  }

  /// Check if any entity is likely following the user.
  List<FollowAlert> detectFollowers() {
    _evictOldRecords();
    final alerts = <FollowAlert>[];

    for (final entry in _entityCorrelation.entries) {
      if (entry.value >= _minCorrelationPoints) {
        alerts.add(FollowAlert(
          entityId: entry.key,
          correlationCount: entry.value,
          confidence: (entry.value / (_minCorrelationPoints * 2)).clamp(0.0, 1.0),
        ));
      }
    }

    return alerts;
  }

  void _evictOldRecords() {
    final cutoff = DateTime.now().subtract(_timeWindow);
    _records.removeWhere((r) => r.timestamp.isBefore(cutoff));
    // Rebuild correlation counts from valid records
    _entityCorrelation.clear();
    for (final record in _records) {
      _entityCorrelation[record.entityId] =
          (_entityCorrelation[record.entityId] ?? 0) + 1;
    }
  }

  double _haversine(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371000.0;
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRad(double deg) => deg * pi / 180;

  void reset() {
    _records.clear();
    _entityCorrelation.clear();
  }
}

class _ProximityRecord {
  final String entityId;
  final double distance;
  final DateTime timestamp;
  const _ProximityRecord({
    required this.entityId,
    required this.distance,
    required this.timestamp,
  });
}

class FollowAlert {
  final String entityId;
  final int correlationCount;
  final double confidence;
  const FollowAlert({
    required this.entityId,
    required this.correlationCount,
    required this.confidence,
  });
}
