import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/models/scalability_config_model.dart';
import 'package:kawach/services/scalability/connection_pool_manager.dart';

void main() {
  group('ConnectionPoolManager', () {
    late ConnectionPoolManager pool;

    setUp(() {
      pool = ConnectionPoolManager(
        config: const ScalabilityConfig(maxHealthCheckFailures: 2),
      );
    });

    tearDown(() => pool.dispose());

    test('starts healthy', () {
      expect(pool.isHealthy, isTrue);
      expect(pool.consecutiveFailures, 0);
    });

    test('reportUnhealthy marks the pool as unhealthy', () {
      pool.reportUnhealthy();
      expect(pool.isHealthy, isFalse);
      expect(pool.consecutiveFailures, 2);
    });

    test('attemptRecovery can restore health', () async {
      pool.reportUnhealthy();
      final ok = await pool.attemptRecovery();
      expect(ok, isTrue);
      expect(pool.isHealthy, isTrue);
    });

    test('reset clears all state', () {
      pool.reportUnhealthy();
      pool.reset();
      expect(pool.isHealthy, isTrue);
      expect(pool.consecutiveFailures, 0);
      expect(pool.lastSuccessfulCheck, isNull);
    });
  });
}
