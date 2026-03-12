import 'package:flutter/foundation.dart';

import '../utils/constants.dart';
import 'danger_zone_service.dart';
import 'predictive_danger_service.dart';

/// Composite real-time risk analysis combining time, location,
/// and danger zone density into an actionable risk level.
class RiskAnalysisService extends ChangeNotifier {
  double _compositeScore = 0.0;
  String _riskLevel = 'LOW';
  List<String> _alerts = [];
  bool _shouldWarn = false;

  double get compositeScore => _compositeScore;
  String get riskLevel => _riskLevel;
  List<String> get alerts => _alerts;
  bool get shouldWarn => _shouldWarn;

  Future<void> analyzeCurrentRisk({
    required double lat,
    required double lng,
    required DangerZoneService dangerZoneService,
    required PredictiveDangerService predictiveService,
  }) async {
    _alerts = [];
    double score = 0.0;

    // 1. Predictive AI score
    final predictiveScore = await predictiveService.analyzePredictiveRisk(
      lat: lat,
      lng: lng,
      dangerZones: dangerZoneService.dangerZones,
    );
    score += predictiveScore * 0.5; // 50% weight

    // 2. Proximity density
    final nearbyZones =
        dangerZoneService.getNearbyZones(lat, lng, radiusMeters: 500);
    final densityScore = (nearbyZones.length * 1.5).clamp(0, 5);
    score += densityScore * 0.3; // 30% weight
    if (nearbyZones.isNotEmpty) {
      _alerts.add('${nearbyZones.length} danger zone(s) within 500m');
    }

    // 3. Time factor
    final hour = DateTime.now().hour;
    if (hour >= 22 || hour < 5) {
      score += 3.0 * 0.2;
      _alerts.add('High-risk time: night hours');
    } else if (hour >= 19) {
      score += 1.5 * 0.2;
      _alerts.add('Elevated risk: evening hours');
    }

    // Add predictive factors
    _alerts.addAll(predictiveService.riskFactors);

    _compositeScore = score.clamp(0, 10);
    _shouldWarn = _compositeScore >= AppThresholds.mediumRiskScore;

    if (_compositeScore >= AppThresholds.highRiskScore) {
      _riskLevel = 'HIGH';
    } else if (_compositeScore >= AppThresholds.mediumRiskScore) {
      _riskLevel = 'MODERATE';
    } else {
      _riskLevel = 'LOW';
    }

    notifyListeners();
  }
}
