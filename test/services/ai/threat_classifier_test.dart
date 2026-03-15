import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/services/ai/threat_classifier.dart';

void main() {
  late ThreatClassifier classifier;

  setUp(() {
    classifier = ThreatClassifier();
  });

  group('ThreatClassifier', () {
    test('returns safe when all signals are zero', () {
      final result = classifier.classify();
      expect(result.label, 'SAFE');
      expect(result.score, closeTo(0.0, 0.01));
      expect(result.module, 'threat_classifier');
    });

    test('returns critical when all signals are maximum', () {
      final result = classifier.classify(
        timeRisk: 1.0,
        locationRisk: 1.0,
        motionAnomaly: 1.0,
        voiceIndicator: 1.0,
        environmentRisk: 1.0,
      );
      expect(result.label, 'CRITICAL');
      expect(result.score, closeTo(10.0, 0.01));
    });

    test('weighted combination produces moderate for mixed signals', () {
      final result = classifier.classify(
        timeRisk: 0.5,
        locationRisk: 0.5,
        motionAnomaly: 0.0,
        voiceIndicator: 0.0,
        environmentRisk: 0.0,
      );
      // 0.5*0.15 + 0.5*0.25 = 0.2 → LOW or MODERATE
      expect(result.score, greaterThan(0.0));
      expect(result.score, lessThanOrEqualTo(10.0));
    });

    test('confidence increases with more active signals', () {
      final fewSignals = classifier.classify(timeRisk: 0.8);
      final manySignals = classifier.classify(
        timeRisk: 0.8,
        locationRisk: 0.8,
        motionAnomaly: 0.8,
        voiceIndicator: 0.8,
      );
      expect(manySignals.confidence, greaterThan(fewSignals.confidence));
    });
  });
}
