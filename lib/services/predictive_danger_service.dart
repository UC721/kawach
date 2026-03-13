import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/danger_zone_model.dart';
import '../utils/constants.dart';

/// Analyzes patterns to predict danger before user enters unsafe areas.
class PredictiveDangerService extends ChangeNotifier {
  final SupabaseClient _db = Supabase.instance.client;

  double _riskScore = 0.0;
  List<String> _riskFactors = [];

  double get riskScore => _riskScore;
  List<String> get riskFactors => _riskFactors;

  // ── Calculate predictive risk score ─────────────────────────
  Future<double> analyzePredictiveRisk({
    required double lat,
    required double lng,
    required List<DangerZoneModel> dangerZones,
  }) async {
    _riskFactors = [];
    double score = 0.0;

    // Factor 1: Time of day risk
    final hour = DateTime.now().hour;
    final timeRisk = _calculateTimeRisk(hour);
    score += timeRisk;
    if (timeRisk > 2) {
      _riskFactors.add(_getTimeRiskText(hour));
    }

    // Factor 2: Nearby danger zones
    final nearbyZones = dangerZones.where((z) {
      return Geolocator.distanceBetween(lat, lng, z.lat, z.lng) <= 1000;
    }).toList();

    for (final zone in nearbyZones) {
      switch (zone.severity) {
        case DangerSeverity.critical:
          score += 4.0;
          _riskFactors.add('Critical danger zone within 1km');
          break;
        case DangerSeverity.high:
          score += 2.5;
          _riskFactors.add('High-risk area nearby');
          break;
        case DangerSeverity.medium:
          score += 1.5;
          break;
        case DangerSeverity.low:
          score += 0.5;
          break;
      }
    }

    // Factor 3: Recent reports in last 24 hours
    final recentReports = await _getRecentReportsNear(lat, lng);
    if (recentReports > 5) {
      score += 2.0;
      _riskFactors
          .add('$recentReports incidents reported in this area (24h)');
    } else if (recentReports > 2) {
      score += 1.0;
      _riskFactors
          .add('$recentReports recent incidents nearby');
    }

    _riskScore = score.clamp(0, 10);
    notifyListeners();
    return _riskScore;
  }

  double _calculateTimeRisk(int hour) {
    if (hour >= 23 || hour < 4) return 4.0;  // Late night – very high
    if (hour >= 20 || hour < 6) return 2.5;  // Evening/early morning
    if (hour >= 18) return 1.0;              // Dusk
    return 0.0;                              // Daytime – safe
  }

  String _getTimeRiskText(int hour) {
    if (hour >= 23 || hour < 4) return 'Late night – high risk period';
    if (hour >= 20) return 'Night time – elevated risk';
    if (hour < 6) return 'Early morning – increased caution';
    return 'Evening hours – stay alert';
  }

  Future<int> _getRecentReportsNear(double lat, double lng) async {
    try {
      final yesterday = DateTime.now().subtract(const Duration(hours: 24));
      final res = await _db
          .from(FSCollection.reports)
          .select()
          .gte('created_at', yesterday.toIso8601String());

      int count = 0;
      for (final data in res as List<dynamic>) {
        final double? rLat = data['latitude'] ?? data['lat'];
        final double? rLng = data['longitude'] ?? data['lng'];
        if (rLat != null && rLng != null) {
          final dist = Geolocator.distanceBetween(
              lat, lng, rLat, rLng);
          if (dist <= 1000) count++;
        }
      }
      return count;
    } catch (_) {
      return 0;
    }
  }

  String getRiskLabel() {
    if (_riskScore >= AppThresholds.highRiskScore) return 'HIGH RISK';
    if (_riskScore >= AppThresholds.mediumRiskScore) return 'MODERATE RISK';
    return 'LOW RISK';
  }
}
