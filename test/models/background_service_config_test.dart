import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/models/background_service_config.dart';

void main() {
  group('BackgroundServiceConfig', () {
    test('default constructor provides sensible defaults', () {
      const config = BackgroundServiceConfig();

      expect(config.notificationTitle, 'KAWACH Active');
      expect(config.notificationBody, 'Your safety shield is running');
      expect(config.locationUpdateIntervalSec, 15);
      expect(config.enableLocationTracking, isTrue);
      expect(config.enableShakeDetection, isTrue);
      expect(config.enableMotionDetection, isTrue);
      expect(config.enableVoiceDetection, isFalse);
      expect(config.autoStopThresholdSec, 30);
    });

    test('emergency factory enables all monitors with fast updates', () {
      final config = BackgroundServiceConfig.emergency();

      expect(config.notificationTitle, contains('Emergency'));
      expect(config.locationUpdateIntervalSec, 5);
      expect(config.enableLocationTracking, isTrue);
      expect(config.enableShakeDetection, isTrue);
      expect(config.enableMotionDetection, isTrue);
      expect(config.enableVoiceDetection, isTrue);
      expect(config.autoStopThresholdSec, 0);
    });

    test('passive factory uses longer interval and fewer monitors', () {
      final config = BackgroundServiceConfig.passive();

      expect(config.locationUpdateIntervalSec, 60);
      expect(config.enableLocationTracking, isTrue);
      expect(config.enableShakeDetection, isFalse);
      expect(config.enableMotionDetection, isFalse);
      expect(config.enableVoiceDetection, isFalse);
    });

    test('copyWith overrides only specified fields', () {
      const original = BackgroundServiceConfig();
      final modified = original.copyWith(
        notificationTitle: 'Custom Title',
        locationUpdateIntervalSec: 30,
      );

      expect(modified.notificationTitle, 'Custom Title');
      expect(modified.locationUpdateIntervalSec, 30);
      // Unchanged fields should remain the same
      expect(modified.notificationBody, original.notificationBody);
      expect(modified.enableLocationTracking, original.enableLocationTracking);
      expect(modified.enableShakeDetection, original.enableShakeDetection);
    });

    test('toMap / fromMap round-trip preserves all fields', () {
      const original = BackgroundServiceConfig(
        notificationTitle: 'Test',
        notificationBody: 'Body',
        locationUpdateIntervalSec: 42,
        enableLocationTracking: false,
        enableShakeDetection: false,
        enableMotionDetection: true,
        enableVoiceDetection: true,
        autoStopThresholdSec: 99,
      );

      final restored = BackgroundServiceConfig.fromMap(original.toMap());
      expect(restored, equals(original));
    });

    test('fromMap uses defaults for missing keys', () {
      final config = BackgroundServiceConfig.fromMap({});

      expect(config.notificationTitle, 'KAWACH Active');
      expect(config.locationUpdateIntervalSec, 15);
      expect(config.enableVoiceDetection, isFalse);
    });

    test('equality and hashCode', () {
      const a = BackgroundServiceConfig();
      const b = BackgroundServiceConfig();
      final c = BackgroundServiceConfig.emergency();

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
