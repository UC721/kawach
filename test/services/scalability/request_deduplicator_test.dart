import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/models/scalability_config_model.dart';
import 'package:kawach/services/scalability/request_deduplicator.dart';

void main() {
  group('RequestDeduplicator', () {
    late RequestDeduplicator dedup;

    setUp(() {
      dedup = RequestDeduplicator(
        config: const ScalabilityConfig(
          deduplicationWindow: Duration(seconds: 1),
        ),
      );
    });

    test('first request is allowed', () {
      expect(dedup.shouldProcess('sos-abc'), isTrue);
    });

    test('duplicate request within window is rejected', () {
      dedup.shouldProcess('sos-abc');
      expect(dedup.shouldProcess('sos-abc'), isFalse);
    });

    test('different keys are independent', () {
      dedup.shouldProcess('sos-1');
      expect(dedup.shouldProcess('sos-2'), isTrue);
    });

    test('isDuplicate returns true for tracked key', () {
      dedup.shouldProcess('k1');
      expect(dedup.isDuplicate('k1'), isTrue);
      expect(dedup.isDuplicate('k2'), isFalse);
    });

    test('expired keys are purged', () async {
      dedup.shouldProcess('old');
      await Future<void>.delayed(const Duration(seconds: 2));
      expect(dedup.shouldProcess('old'), isTrue);
    });

    test('remove clears specific key', () {
      dedup.shouldProcess('k');
      dedup.remove('k');
      expect(dedup.shouldProcess('k'), isTrue);
    });

    test('clear removes all keys', () {
      dedup.shouldProcess('a');
      dedup.shouldProcess('b');
      dedup.clear();
      expect(dedup.trackedCount, 0);
    });
  });
}
