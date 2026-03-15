import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/models/background_service_config.dart';
import 'package:kawach/services/background/background_service.dart';

void main() {
  late BackgroundService service;

  setUp(() {
    service = BackgroundService();
  });

  tearDown(() {
    service.dispose();
  });

  group('BackgroundService', () {
    test('initial state is not running', () {
      expect(service.isRunning, isFalse);
      expect(service.startedAt, isNull);
      expect(service.uptime, Duration.zero);
    });

    test('startService transitions to running', () async {
      // Note: _showForegroundNotification will fail in test because there is
      // no real notification plugin.  We catch it to test state logic only.
      try {
        await service.startService();
      } catch (_) {
        // Expected – no notification plugin in unit test
      }

      expect(service.isRunning, isTrue);
      expect(service.startedAt, isNotNull);
    });

    test('startService is idempotent when already running', () async {
      try {
        await service.startService();
      } catch (_) {}
      final firstStart = service.startedAt;

      try {
        await service.startService();
      } catch (_) {}

      // startedAt should not change on second call
      expect(service.startedAt, firstStart);
    });

    test('stopService with force stops immediately', () async {
      try {
        await service.startService();
      } catch (_) {}

      try {
        await service.stopService(force: true);
      } catch (_) {}

      expect(service.isRunning, isFalse);
      expect(service.startedAt, isNull);
    });

    test('stopService without force respects autoStopThreshold', () async {
      // Default threshold is 30s; the service just started so it should refuse
      try {
        await service.startService();
      } catch (_) {}

      try {
        await service.stopService();
      } catch (_) {}

      // Should still be running because < 30s has elapsed
      expect(service.isRunning, isTrue);
    });

    test('stopService without force stops when threshold is 0', () async {
      final config = BackgroundServiceConfig.emergency(); // threshold = 0
      try {
        await service.startService(config: config);
      } catch (_) {}

      try {
        await service.stopService();
      } catch (_) {}

      expect(service.isRunning, isFalse);
    });

    test('updateConfig replaces active configuration', () async {
      try {
        await service.startService();
      } catch (_) {}

      final newConfig = BackgroundServiceConfig.emergency();
      try {
        await service.updateConfig(newConfig);
      } catch (_) {}

      expect(service.config, equals(newConfig));
    });

    test('config defaults to standard BackgroundServiceConfig', () {
      expect(service.config, equals(const BackgroundServiceConfig()));
    });

    test('uptime increases after starting', () async {
      try {
        await service.startService(
          config: BackgroundServiceConfig.emergency(),
        );
      } catch (_) {}

      // Small delay so uptime is non-zero
      await Future.delayed(const Duration(milliseconds: 50));

      expect(service.uptime.inMilliseconds, greaterThan(0));
    });
  });
}
