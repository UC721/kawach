import 'package:flutter/material.dart';

enum DangerSeverity { low, medium, high, critical }

class DangerZoneModel {
  final String zoneId;
  final double lat;
  final double lng;
  final DangerSeverity severity;
  final int reportCount;
  final DateTime lastUpdated;

  DangerZoneModel({
    required this.zoneId,
    required this.lat,
    required this.lng,
    required this.severity,
    required this.reportCount,
    required this.lastUpdated,
  });

  factory DangerZoneModel.fromMap(Map<String, dynamic> data) {
    return DangerZoneModel(
      zoneId: (data['id'] ?? data['zoneId'] ?? data['zone_id'] ?? '').toString(),
      lat: (data['latitude'] ?? data['lat'] ?? 0).toDouble(),
      lng: (data['longitude'] ?? data['lng'] ?? 0).toDouble(),
      severity: DangerSeverity.values.firstWhere(
        (e) => e.name == (data['severity'] ?? 'low'),
        orElse: () => DangerSeverity.low,
      ),
      reportCount: data['report_count'] ?? data['reportCount'] ?? 0,
      lastUpdated: (data['created_at'] ?? data['last_updated'] ?? data['lastUpdated']) != null
          ? DateTime.parse(data['created_at'] ?? data['last_updated'] ?? data['lastUpdated'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': zoneId,
        'latitude': lat,
        'longitude': lng,
        'severity': severity.name,
        'created_at': lastUpdated.toIso8601String(),
        'description': 'Danger Zone',
      };

  Color get severityColor {
    switch (severity) {
      case DangerSeverity.low:
        return const Color(0xFF43A047);
      case DangerSeverity.medium:
        return const Color(0xFFF57C00);
      case DangerSeverity.high:
        return const Color(0xFFE53935);
      case DangerSeverity.critical:
        return const Color(0xFF6A1B9A);
    }
  }
}
