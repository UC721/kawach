import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/services/ai/behavior_analyzer.dart';

void main() {
  late BehaviorAnalyzer analyzer;

  setUp(() {
    analyzer = BehaviorAnalyzer(maxHistory: 20);
  });

  group('BehaviorAnalyzer', () {
    test('returns unknown with insufficient data', () {
      analyzer.addLocationSample(
          lat: 28.6, lng: 77.2, timestamp: DateTime.now());
      final result = analyzer.analyze(currentHour: 12);
      expect(result.label, 'UNKNOWN');
    });

    test('classifies stationary when speed is zero', () {
      for (int i = 0; i < 10; i++) {
        analyzer.addLocationSample(
          lat: 28.6,
          lng: 77.2,
          timestamp: DateTime.now().add(Duration(seconds: i)),
          speed: 0.0,
        );
      }
      final result = analyzer.analyze(currentHour: 12, currentSpeed: 0.0);
      expect(result.label, 'STATIONARY');
    });

    test('classifies normal for steady walking', () {
      for (int i = 0; i < 10; i++) {
        analyzer.addLocationSample(
          lat: 28.6 + i * 0.0001,
          lng: 77.2,
          timestamp: DateTime.now().add(Duration(seconds: i * 5)),
          speed: 1.5,
        );
      }
      final result = analyzer.analyze(currentHour: 12, currentSpeed: 1.5);
      expect(result.label, 'NORMAL');
    });

    test('danger zone increases risk score', () {
      for (int i = 0; i < 5; i++) {
        analyzer.addLocationSample(
          lat: 28.6,
          lng: 77.2,
          timestamp: DateTime.now().add(Duration(seconds: i)),
          speed: 1.5,
        );
      }
      final safe = analyzer.analyze(currentHour: 12, isInDangerZone: false);
      final danger = analyzer.analyze(currentHour: 12, isInDangerZone: true);
      expect(danger.score, greaterThan(safe.score));
    });

    test('reset clears history', () {
      for (int i = 0; i < 10; i++) {
        analyzer.addLocationSample(
          lat: 28.6,
          lng: 77.2,
          timestamp: DateTime.now().add(Duration(seconds: i)),
          speed: 0.0,
        );
      }
      analyzer.reset();
      final result = analyzer.analyze(currentHour: 12);
      expect(result.label, 'UNKNOWN');
    });
  });
}
