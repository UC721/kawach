import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/services/ai/anomaly_detector.dart';

void main() {
  late AnomalyDetector detector;

  setUp(() {
    detector = AnomalyDetector(windowSize: 20);
  });

  group('AnomalyDetector', () {
    test('returns unknown when insufficient data', () {
      final result = detector.analyze(magnitude: 9.8, delta: 0.1);
      expect(result.label, 'UNKNOWN');
      expect(result.confidence, 0.0);
    });

    test('classifies normal after stable readings', () {
      // Feed stable readings
      for (int i = 0; i < 10; i++) {
        detector.analyze(magnitude: 9.8, delta: 0.2);
      }
      final result = detector.analyze(magnitude: 9.8, delta: 0.3);
      expect(result.label, isNot('FLEEING'));
      expect(result.module, 'anomaly_detector');
    });

    test('detects anomaly with sudden spike', () {
      // Feed stable readings
      for (int i = 0; i < 10; i++) {
        detector.analyze(magnitude: 9.8, delta: 0.2);
      }
      // Sudden spike
      final result = detector.analyze(magnitude: 30.0, delta: 25.0);
      expect(result.score, greaterThan(3.0));
    });

    test('reset clears the window', () {
      for (int i = 0; i < 10; i++) {
        detector.analyze(magnitude: 9.8, delta: 0.2);
      }
      detector.reset();
      final result = detector.analyze(magnitude: 9.8, delta: 0.2);
      expect(result.label, 'UNKNOWN'); // back to insufficient data
    });
  });
}
