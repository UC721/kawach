import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/models/scalability_config_model.dart';
import 'package:kawach/services/scalability/batch_processor.dart';

void main() {
  group('BatchProcessor', () {
    late BatchProcessor processor;
    final flushed = <String, List<Map<String, dynamic>>>{};

    setUp(() {
      flushed.clear();
      processor = BatchProcessor(
        config: const ScalabilityConfig(
          batchMaxSize: 3,
          batchMaxRetries: 2,
        ),
        onFlush: (table, rows) async {
          flushed.putIfAbsent(table, () => []).addAll(rows);
        },
      );
    });

    test('enqueue adds to pending count', () {
      processor.enqueue('locations', {'lat': 1.0, 'lng': 2.0});
      expect(processor.pendingCount, 1);
    });

    test('flush sends all pending operations', () async {
      processor.enqueue('locations', {'lat': 1.0});
      processor.enqueue('locations', {'lat': 2.0});
      await processor.flush();
      expect(flushed['locations']!.length, 2);
      expect(processor.totalFlushed, 2);
      expect(processor.pendingCount, 0);
    });

    test('auto-flushes when batch is full', () async {
      // batchMaxSize is 3, so the third enqueue triggers a flush.
      processor.enqueue('t', {'a': 1});
      processor.enqueue('t', {'a': 2});
      processor.enqueue('t', {'a': 3});
      // Give time for the async flush.
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(flushed['t']!.length, 3);
    });

    test('retries failed operations up to max retries', () async {
      var callCount = 0;
      final failingProcessor = BatchProcessor(
        config: const ScalabilityConfig(batchMaxRetries: 2),
        onFlush: (table, rows) async {
          callCount++;
          if (callCount <= 2) throw Exception('fail');
        },
      );
      failingProcessor.enqueue('t', {'a': 1});
      await failingProcessor.flush(); // 1st attempt fails
      await failingProcessor.flush(); // 2nd attempt (retry) fails
      await failingProcessor.flush(); // dropped after max retries
      expect(failingProcessor.totalFailed, 1);
    });

    test('stop flushes remaining and cancels timer', () async {
      processor.start();
      processor.enqueue('t', {'a': 1});
      await processor.stop();
      expect(flushed['t']!.length, 1);
    });
  });
}
