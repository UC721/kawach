import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/models/ai_prediction_model.dart';

void main() {
  group('AIPrediction', () {
    test('creates with required fields', () {
      final p = AIPrediction(
        module: 'test',
        label: 'HIGH',
        confidence: 0.9,
      );
      expect(p.module, 'test');
      expect(p.label, 'HIGH');
      expect(p.confidence, 0.9);
      expect(p.score, 0.0);
      expect(p.metadata, isEmpty);
    });

    test('confidence classification', () {
      expect(
          AIPrediction(module: 'x', label: 'x', confidence: 0.9)
              .isHighConfidence,
          isTrue);
      expect(
          AIPrediction(module: 'x', label: 'x', confidence: 0.6)
              .isMediumConfidence,
          isTrue);
      expect(
          AIPrediction(module: 'x', label: 'x', confidence: 0.3)
              .isLowConfidence,
          isTrue);
    });

    test('serialises to and from map', () {
      final original = AIPrediction(
        module: 'threat',
        label: 'CRITICAL',
        confidence: 0.95,
        score: 8.5,
        metadata: {'key': 'value'},
      );
      final map = original.toMap();
      final restored = AIPrediction.fromMap(map);

      expect(restored.module, original.module);
      expect(restored.label, original.label);
      expect(restored.confidence, original.confidence);
      expect(restored.score, original.score);
      expect(restored.metadata['key'], 'value');
    });

    test('toString includes module and confidence', () {
      final p = AIPrediction(
        module: 'nlp',
        label: 'PANIC',
        confidence: 0.85,
      );
      expect(p.toString(), contains('nlp'));
      expect(p.toString(), contains('PANIC'));
      expect(p.toString(), contains('85.0%'));
    });
  });
}
