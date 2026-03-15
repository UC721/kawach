import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/models/scalability_config_model.dart';

void main() {
  group('ScalabilityConfig', () {
    test('default constructor provides sensible values', () {
      const config = ScalabilityConfig();
      expect(config.memoryCacheMaxItems, 1000);
      expect(config.cacheTtl, const Duration(minutes: 5));
      expect(config.rateLimitMaxTokens, 60);
      expect(config.batchMaxSize, 50);
      expect(config.circuitBreakerFailureThreshold, 5);
      expect(config.maxRealtimeChannels, 10);
      expect(config.deduplicationWindow, const Duration(seconds: 10));
      expect(config.healthCheckInterval, const Duration(seconds: 30));
    });

    test('production factory has higher limits', () {
      final config = ScalabilityConfig.production();
      expect(config.memoryCacheMaxItems, 5000);
      expect(config.rateLimitMaxTokens, 120);
      expect(config.batchMaxSize, 100);
      expect(config.circuitBreakerFailureThreshold, 10);
      expect(config.maxRealtimeChannels, 20);
    });

    test('copyWith replaces only specified fields', () {
      const original = ScalabilityConfig();
      final modified = original.copyWith(memoryCacheMaxItems: 2000);
      expect(modified.memoryCacheMaxItems, 2000);
      expect(modified.cacheTtl, original.cacheTtl);
      expect(modified.rateLimitMaxTokens, original.rateLimitMaxTokens);
    });

    test('toMap / fromMap round-trips correctly', () {
      const original = ScalabilityConfig();
      final map = original.toMap();
      final restored = ScalabilityConfig.fromMap(map);

      expect(restored.memoryCacheMaxItems, original.memoryCacheMaxItems);
      expect(restored.cacheTtl, original.cacheTtl);
      expect(restored.rateLimitMaxTokens, original.rateLimitMaxTokens);
      expect(restored.batchMaxSize, original.batchMaxSize);
      expect(
        restored.circuitBreakerFailureThreshold,
        original.circuitBreakerFailureThreshold,
      );
      expect(restored.maxRealtimeChannels, original.maxRealtimeChannels);
      expect(restored.deduplicationWindow, original.deduplicationWindow);
    });

    test('fromMap with empty map uses defaults', () {
      final config = ScalabilityConfig.fromMap({});
      expect(config.memoryCacheMaxItems, 1000);
      expect(config.rateLimitMaxTokens, 60);
    });
  });
}
