import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/models/scalability_config_model.dart';
import 'package:kawach/services/scalability/circuit_breaker.dart';

void main() {
  group('CircuitBreaker', () {
    late CircuitBreaker breaker;

    setUp(() {
      breaker = CircuitBreaker(
        name: 'test',
        config: const ScalabilityConfig(
          circuitBreakerFailureThreshold: 3,
          circuitBreakerResetTimeout: Duration(milliseconds: 100),
          circuitBreakerSuccessThreshold: 2,
        ),
      );
    });

    test('starts in closed state', () {
      expect(breaker.state, CircuitState.closed);
      expect(breaker.allowRequest, isTrue);
    });

    test('opens after reaching failure threshold', () async {
      for (var i = 0; i < 3; i++) {
        await breaker.execute<int>(
          () async => throw Exception('fail'),
          fallback: () async => -1,
        );
      }
      expect(breaker.state, CircuitState.open);
      expect(breaker.allowRequest, isFalse);
    });

    test('returns fallback when open', () async {
      // Force open.
      for (var i = 0; i < 3; i++) {
        await breaker.execute<int>(
          () async => throw Exception('fail'),
          fallback: () async => -1,
        );
      }
      final result = await breaker.execute<int>(
        () async => 42,
        fallback: () async => -1,
      );
      expect(result, -1);
    });

    test('transitions to half-open after reset timeout', () async {
      for (var i = 0; i < 3; i++) {
        await breaker.execute<int>(
          () async => throw Exception('fail'),
          fallback: () async => -1,
        );
      }
      expect(breaker.state, CircuitState.open);

      // Wait for reset timeout.
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(breaker.allowRequest, isTrue);
      expect(breaker.state, CircuitState.halfOpen);
    });

    test('closes after enough successes in half-open state', () async {
      // Open the breaker.
      for (var i = 0; i < 3; i++) {
        await breaker.execute<int>(
          () async => throw Exception('fail'),
          fallback: () async => -1,
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Two successes should close it.
      await breaker.execute<int>(
        () async => 1,
        fallback: () async => -1,
      );
      await breaker.execute<int>(
        () async => 2,
        fallback: () async => -1,
      );
      expect(breaker.state, CircuitState.closed);
    });

    test('re-opens on failure during half-open', () async {
      for (var i = 0; i < 3; i++) {
        await breaker.execute<int>(
          () async => throw Exception('fail'),
          fallback: () async => -1,
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));

      await breaker.execute<int>(
        () async => throw Exception('fail again'),
        fallback: () async => -1,
      );
      expect(breaker.state, CircuitState.open);
    });

    test('reset returns to closed state', () async {
      for (var i = 0; i < 3; i++) {
        await breaker.execute<int>(
          () async => throw Exception('fail'),
          fallback: () async => -1,
        );
      }
      breaker.reset();
      expect(breaker.state, CircuitState.closed);
      expect(breaker.failureCount, 0);
    });
  });
}
