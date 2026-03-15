import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/services/scalability/data_partitioner.dart';

void main() {
  group('DataPartitioner', () {
    const partitioner = DataPartitioner();

    group('regionKeyFor', () {
      test('returns 0-based region key', () {
        final key = partitioner.regionKeyFor(0, 0);
        expect(key, greaterThanOrEqualTo(0));
        expect(key, lessThan(256));
      });

      test('different locations produce different keys', () {
        final k1 = partitioner.regionKeyFor(40.7128, -74.0060); // NYC
        final k2 = partitioner.regionKeyFor(-33.8688, 151.2093); // Sydney
        expect(k1, isNot(equals(k2)));
      });

      test('nearby locations produce the same key', () {
        final k1 = partitioner.regionKeyFor(40.7128, -74.0060);
        final k2 = partitioner.regionKeyFor(40.7130, -74.0058);
        expect(k1, equals(k2));
      });

      test('handles edge coordinates', () {
        expect(partitioner.regionKeyFor(-90, -180),
            greaterThanOrEqualTo(0));
        expect(partitioner.regionKeyFor(90, 180),
            greaterThanOrEqualTo(0));
      });
    });

    group('monthPartition', () {
      test('formats correctly', () {
        expect(
          partitioner.monthPartition(DateTime(2026, 3, 15)),
          '2026_03',
        );
        expect(
          partitioner.monthPartition(DateTime(2025, 12, 1)),
          '2025_12',
        );
      });
    });

    group('monthPartitionRange', () {
      test('returns all months between start and end', () {
        final range = partitioner.monthPartitionRange(
          DateTime(2026, 1, 10),
          DateTime(2026, 4, 5),
        );
        expect(range, ['2026_01', '2026_02', '2026_03', '2026_04']);
      });

      test('returns single month when start == end month', () {
        final range = partitioner.monthPartitionRange(
          DateTime(2026, 3, 1),
          DateTime(2026, 3, 31),
        );
        expect(range, ['2026_03']);
      });
    });

    group('cursorPage', () {
      test('returns default pagination map', () {
        final page = partitioner.cursorPage();
        expect(page['limit'], 50);
        expect(page['order'], 'created_at');
        expect(page['ascending'], isFalse);
        expect(page.containsKey('after'), isFalse);
      });

      test('includes afterId when provided', () {
        final page = partitioner.cursorPage(afterId: 'abc-123');
        expect(page['after'], 'abc-123');
      });

      test('respects custom page size', () {
        final page = partitioner.cursorPage(pageSize: 20);
        expect(page['limit'], 20);
      });
    });
  });
}
