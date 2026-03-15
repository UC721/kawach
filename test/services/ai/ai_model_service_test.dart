import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/models/danger_zone_model.dart';
import 'package:kawach/services/ai/ai_model_service.dart';

void main() {
  late AIModelService service;

  setUp(() {
    service = AIModelService();
  });

  group('AIModelService', () {
    // ── 1. Emergency / SOS ──────────────────────────────────────
    test('assessEmergencyThreat returns valid prediction', () {
      final result = service.assessEmergencyThreat(
        timeRisk: 0.8,
        locationRisk: 0.6,
        motionAnomaly: 0.0,
        voiceIndicator: 0.9,
      );
      expect(result.module, 'threat_classifier');
      expect(result.score, greaterThan(0.0));
      expect(service.latestThreat, isNotNull);
    });

    // ── 2. Evidence Vault ───────────────────────────────────────
    test('classifyEvidenceScene returns scene type', () {
      final result = service.classifyEvidenceScene(hour: 2);
      expect(result.module, 'scene_analyzer');
      expect(result.score, greaterThan(0.0)); // Night time
      expect(service.latestScene, isNotNull);
    });

    // ── 3. Guardian Network ─────────────────────────────────────
    test('scoreGuardianAlertUrgency scales with risk', () {
      final low = service.scoreGuardianAlertUrgency(
        distanceToUser: 1000,
        currentRiskScore: 2.0,
        hour: 12,
      );
      final high = service.scoreGuardianAlertUrgency(
        distanceToUser: 100,
        currentRiskScore: 9.0,
        hour: 1,
      );
      expect(high.score, greaterThan(low.score));
    });

    // ── 4. Route Safety ─────────────────────────────────────────
    test('predictRouteRisk returns valid prediction', () {
      final result = service.predictRouteRisk(
        waypoints: [
          {'lat': 28.6, 'lng': 77.2},
        ],
        dangerZones: [],
        hour: 12,
      );
      expect(result.module, 'route_risk_predictor');
      expect(service.latestRoute, isNotNull);
    });

    // ── 5. Voice Detection ──────────────────────────────────────
    test('analyzeSpeech detects panic', () {
      final result = service.analyzeSpeech('help me please stop');
      expect(result.label, 'PANIC');
      expect(service.latestNlp, isNotNull);
    });

    test('isSpeechPanic returns boolean', () {
      expect(service.isSpeechPanic('help me'), isTrue);
      expect(service.isSpeechPanic('good morning'), isFalse);
    });

    // ── 6. Motion Detection ─────────────────────────────────────
    test('analyzeMotion feeds anomaly detector', () {
      final result = service.analyzeMotion(magnitude: 9.8, delta: 0.2);
      expect(result.module, 'anomaly_detector');
      expect(service.latestAnomaly, isNotNull);
    });

    // ── 7. Danger Zone ──────────────────────────────────────────
    test('predictDangerZoneSeverity adjusts severity', () {
      final zone = DangerZoneModel(
        zoneId: 'z1',
        lat: 28.6,
        lng: 77.2,
        severity: DangerSeverity.low,
        reportCount: 15,
        lastUpdated: DateTime.now(),
      );
      final result = service.predictDangerZoneSeverity(
        zone: zone,
        hour: 1,
        recentReportCount: 15,
      );
      expect(result.module, 'danger_zone_predictor');
      // High incident count + night time should elevate severity
      expect(result.score, greaterThan(0.0));
    });

    // ── 8. Risk Analysis ────────────────────────────────────────
    test('computeCompositeRisk returns valid prediction', () {
      final result = service.computeCompositeRisk(
        predictiveScore: 5.0,
        nearbyZoneCount: 3,
        hour: 22,
      );
      expect(result.module, 'composite_risk');
      expect(['LOW', 'MODERATE', 'HIGH'], contains(result.label));
    });

    // ── 9. Panic Detection ──────────────────────────────────────
    test('fusePanicSignals returns high confidence when both trigger', () {
      final result = service.fusePanicSignals(
        voiceTriggered: true,
        motionTriggered: true,
        recognisedText: 'help me',
      );
      expect(result.module, 'panic_fusion');
      expect(result.confidence, greaterThanOrEqualTo(0.9));
    });

    test('fusePanicSignals returns lower confidence with single trigger', () {
      final result = service.fusePanicSignals(
        voiceTriggered: true,
        motionTriggered: false,
        recognisedText: 'help me',
      );
      expect(result.confidence, lessThan(0.9));
    });

    // ── 10. Fake Call ───────────────────────────────────────────
    test('suggestFakeCallTiming returns timing suggestion', () {
      final result = service.suggestFakeCallTiming(
        currentRiskScore: 8.0,
        hour: 1,
      );
      expect(result.module, 'fake_call_timing');
      expect(result.metadata['suggested_delay_sec'], isA<int>());
      // High risk should suggest shorter delay
      final delay = result.metadata['suggested_delay_sec'] as int;
      expect(delay, lessThanOrEqualTo(8));
    });

    // ── 11. Offline Emergency ───────────────────────────────────
    test('assessOfflineThreat works without network', () {
      final result = service.assessOfflineThreat(
        hour: 2,
        motionAnomalyDetected: true,
        voicePanicDetected: true,
      );
      expect(result.module, 'offline_threat');
      expect(result.metadata['is_offline'], isTrue);
      expect(result.score, greaterThan(3.0));
    });

    // ── 12. Live Stream ─────────────────────────────────────────
    test('analyzeStreamContext returns stream analysis', () {
      final result = service.analyzeStreamContext(
        hour: 23,
        currentRiskScore: 7.0,
      );
      expect(result.module, 'stream_analysis');
      expect(['STABLE', 'CAUTION', 'HIGH_ALERT'], contains(result.label));
    });

    // ── Behaviour Tracking ──────────────────────────────────────
    test('analyzeBehavior after recording locations', () {
      for (int i = 0; i < 5; i++) {
        service.recordLocation(lat: 28.6, lng: 77.2, speed: 0.0);
      }
      final result = service.analyzeBehavior(currentHour: 12);
      expect(result.module, 'behavior_analyzer');
      expect(service.latestBehavior, isNotNull);
    });

    // ── Reset ───────────────────────────────────────────────────
    test('resetAll clears all predictions', () {
      service.assessEmergencyThreat(timeRisk: 0.5);
      service.analyzeSpeech('help');
      service.analyzeMotion(magnitude: 9.8, delta: 0.2);
      service.resetAll();

      expect(service.latestThreat, isNull);
      expect(service.latestNlp, isNull);
      expect(service.latestAnomaly, isNull);
      expect(service.latestScene, isNull);
      expect(service.latestRoute, isNull);
      expect(service.latestBehavior, isNull);
    });
  });
}
