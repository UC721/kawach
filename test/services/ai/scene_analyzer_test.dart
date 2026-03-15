import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/services/ai/scene_analyzer.dart';

void main() {
  late SceneAnalyzer analyzer;

  setUp(() {
    analyzer = SceneAnalyzer();
  });

  group('SceneAnalyzer', () {
    test('night time increases risk', () {
      final night = analyzer.analyzeScene(hour: 2);
      final day = analyzer.analyzeScene(hour: 12);
      expect(night.score, greaterThan(day.score));
    });

    test('low light increases risk', () {
      final dark = analyzer.analyzeScene(hour: 12, ambientLightLux: 5);
      final bright = analyzer.analyzeScene(hour: 12, ambientLightLux: 500);
      expect(dark.score, greaterThan(bright.score));
    });

    test('isolation increases risk', () {
      final isolated =
          analyzer.analyzeScene(hour: 12, nearbyPeopleEstimate: 0);
      final crowded =
          analyzer.analyzeScene(hour: 12, nearbyPeopleEstimate: 20);
      expect(isolated.score, greaterThan(crowded.score));
    });

    test('classifies scene type correctly', () {
      final indoor =
          analyzer.analyzeScene(hour: 12, isIndoors: true);
      expect(indoor.label, 'INDOOR');

      final isolatedScene = analyzer.analyzeScene(
          hour: 12, isIndoors: false, nearbyPeopleEstimate: 0);
      expect(isolatedScene.label, 'ISOLATED');
    });

    test('module name is correct', () {
      final result = analyzer.analyzeScene(hour: 12);
      expect(result.module, 'scene_analyzer');
    });
  });
}
