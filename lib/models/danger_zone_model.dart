import 'package:cloud_firestore/cloud_firestore.dart';
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

  factory DangerZoneModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DangerZoneModel(
      zoneId: doc.id,
      lat: (data['lat'] as num?)?.toDouble() ?? 0,
      lng: (data['lng'] as num?)?.toDouble() ?? 0,
      severity: DangerSeverity.values.firstWhere(
        (e) => e.name == (data['severity'] ?? 'low'),
        orElse: () => DangerSeverity.low,
      ),
      reportCount: data['reportCount'] ?? 0,
      lastUpdated:
          (data['lastUpdated'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'lat': lat,
        'lng': lng,
        'severity': severity.name,
        'reportCount': reportCount,
        'lastUpdated': Timestamp.fromDate(lastUpdated),
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
