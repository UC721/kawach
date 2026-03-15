import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/models/scalability_config_model.dart';
import 'package:kawach/services/scalability/rate_limiter.dart';

void main() {
  group('RateLimiter', () {
    late RateLimiter limiter;

    setUp(() {
      limiter = RateLimiter(
        config: const ScalabilityConfig(rateLimitMaxTokens: 3),
      );
    });

    test('allows requests up to max tokens', () {
      expect(limiter.tryAcquire('api'), isTrue);
      expect(limiter.tryAcquire('api'), isTrue);
      expect(limiter.tryAcquire('api'), isTrue);
    });

    test('rejects requests when tokens exhausted', () {
      for (var i = 0; i < 3; i++) {
        limiter.tryAcquire('api');
      }
      expect(limiter.tryAcquire('api'), isFalse);
    });

    test('different buckets are independent', () {
      for (var i = 0; i < 3; i++) {
        limiter.tryAcquire('a');
      }
      expect(limiter.tryAcquire('a'), isFalse);
      expect(limiter.tryAcquire('b'), isTrue);
    });

    test('availableTokens reflects consumption', () {
      expect(limiter.availableTokens('api'), 3);
      limiter.tryAcquire('api');
      expect(limiter.availableTokens('api'), 2);
    });

    test('resetBucket restores full capacity', () {
      for (var i = 0; i < 3; i++) {
        limiter.tryAcquire('api');
      }
      limiter.resetBucket('api');
      expect(limiter.availableTokens('api'), 3);
    });

    test('resetAll clears every bucket', () {
      limiter.tryAcquire('a');
      limiter.tryAcquire('b');
      limiter.resetAll();
      expect(limiter.availableTokens('a'), 3);
      expect(limiter.availableTokens('b'), 3);
    });
  });
}
