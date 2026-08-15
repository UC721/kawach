import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/services/mesh/bloom_filter.dart';

void main() {
  group('BloomFilter', () {
    late BloomFilter filter;

    setUp(() {
      filter = BloomFilter(size: 1024, hashCount: 5);
    });

    test('newly created filter contains nothing', () {
      expect(filter.mightContain('any-key'), false);
      expect(filter.count, 0);
    });

    test('added item is found', () {
      filter.add('message-uuid-1:1234567890');
      expect(filter.mightContain('message-uuid-1:1234567890'), true);
    });

    test('item not added is (almost certainly) not found', () {
      filter.add('message-uuid-1:1234567890');
      expect(filter.mightContain('message-uuid-2:9876543210'), false);
    });

    test('count tracks additions', () {
      filter.add('a');
      filter.add('b');
      filter.add('c');
      expect(filter.count, 3);
    });

    test('reset clears all entries', () {
      filter.add('a');
      filter.add('b');
      filter.reset();
      expect(filter.mightContain('a'), false);
      expect(filter.mightContain('b'), false);
      expect(filter.count, 0);
    });

    test('handles many unique items', () {
      for (int i = 0; i < 100; i++) {
        filter.add('item-$i');
      }
      // All inserted items must be found (no false negatives).
      for (int i = 0; i < 100; i++) {
        expect(filter.mightContain('item-$i'), true);
      }
    });

    test('false positive rate is within bounds for optimal filter', () {
      final optimal =
          BloomFilter.optimal(itemCount: 1000, falsePositiveRate: 0.01);

      // Insert 1 000 items.
      for (int i = 0; i < 1000; i++) {
        optimal.add('key-$i');
      }

      // Check 10 000 items that were NOT inserted.
      int falsePositives = 0;
      for (int i = 1000; i < 11000; i++) {
        if (optimal.mightContain('key-$i')) falsePositives++;
      }

      // Allow up to 2 % (generous margin over the 1 % target).
      expect(falsePositives / 10000, lessThan(0.02));
    });

    test('different items produce different hash indices', () {
      // Smoke-test: adding two distinct items should not collide
      // on a reasonably-sized filter.
      final large = BloomFilter(size: 100000, hashCount: 7);
      large.add('alpha');
      // 'beta' should not be present.
      expect(large.mightContain('beta'), false);
    });

    test('duplicate add does not change mightContain result', () {
      filter.add('dup');
      filter.add('dup');
      expect(filter.mightContain('dup'), true);
      expect(filter.count, 2); // count tracks calls, not unique items
    });
  });
}
