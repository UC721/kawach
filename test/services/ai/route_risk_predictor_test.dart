import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/models/danger_zone_model.dart';
import 'package:kawach/services/ai/route_risk_predictor.dart';

void main() {
  late RouteRiskPredictor predictor;

  setUp(() {
    predictor = RouteRiskPredictor();
  });

  group('RouteRiskPredictor', () {
    test('empty route returns safe', () {
      final result = predictor.predictRouteRisk(
        waypoints: [],
        dangerZones: [],
        hour: 12,
      );
      expect(result.label, 'SAFE');
      expect(result.score, 0.0);
      expect(result.confidence, 1.0);
    });

    test('route far from danger zones is low risk', () {
      final waypoints = [
        {'lat': 28.6, 'lng': 77.2},
        {'lat': 28.61, 'lng': 77.21},
      ];
      final zones = [
        DangerZoneModel(
          zoneId: 'z1',
          lat: 30.0,
          lng: 80.0,
          severity: DangerSeverity.high,
          reportCount: 5,
          lastUpdated: DateTime.now(),
        ),
      ];
      final result = predictor.predictRouteRisk(
        waypoints: waypoints,
        dangerZones: zones,
        hour: 12,
      );
      expect(result.score, closeTo(0.0, 1.0));
    });

    test('route through danger zone has higher risk', () {
      final zones = [
        DangerZoneModel(
          zoneId: 'z1',
          lat: 28.605,
          lng: 77.205,
          severity: DangerSeverity.critical,
          reportCount: 10,
          lastUpdated: DateTime.now(),
        ),
      ];
      final waypoints = [
        {'lat': 28.605, 'lng': 77.205}, // directly on the zone
      ];
      final result = predictor.predictRouteRisk(
        waypoints: waypoints,
        dangerZones: zones,
        hour: 12,
      );
      expect(result.score, greaterThan(0.0));
    });

    test('night time increases route risk', () {
      final zones = [
        DangerZoneModel(
          zoneId: 'z1',
          lat: 28.605,
          lng: 77.205,
          severity: DangerSeverity.medium,
          reportCount: 3,
          lastUpdated: DateTime.now(),
        ),
      ];
      final waypoints = [
        {'lat': 28.606, 'lng': 77.206},
      ];
      final day = predictor.predictRouteRisk(
        waypoints: waypoints,
        dangerZones: zones,
        hour: 12,
      );
      final night = predictor.predictRouteRisk(
        waypoints: waypoints,
        dangerZones: zones,
        hour: 1,
      );
      expect(night.score, greaterThanOrEqualTo(day.score));
    });
  });
}
