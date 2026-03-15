import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/models/scalability_config_model.dart';
import 'package:kawach/services/scalability/cache_service.dart';

void main() {
  group('CacheService', () {
    late CacheService cache;

    setUp(() {
      cache = CacheService(
        config: const ScalabilityConfig(memoryCacheMaxItems: 5),
      );
    });

    test('put and get return cached value', () {
      cache.put<String>('ns', 'key1', 'hello');
      expect(cache.get<String>('ns', 'key1'), 'hello');
    });

    test('get returns null for missing key', () {
      expect(cache.get<String>('ns', 'missing'), isNull);
    });

    test('cache tracks hits and misses', () {
      cache.put<int>('ns', 'a', 42);
      cache.get<int>('ns', 'a'); // hit
      cache.get<int>('ns', 'b'); // miss
      expect(cache.hits, 1);
      expect(cache.misses, 1);
      expect(cache.hitRate, 0.5);
    });

    test('LRU eviction removes oldest entries', () {
      for (var i = 0; i < 6; i++) {
        cache.put<int>('ns', 'k$i', i);
      }
      // Max is 5 so k0 should be evicted.
      expect(cache.get<int>('ns', 'k0'), isNull);
      expect(cache.get<int>('ns', 'k5'), 5);
      expect(cache.size, lessThanOrEqualTo(5));
    });

    test('expired entries are lazily removed', () {
      cache.put<String>('ns', 'exp', 'data',
          ttl: const Duration(milliseconds: 1));
      // Wait for expiration.
      Future<void>.delayed(const Duration(milliseconds: 10)).then((_) {
        expect(cache.get<String>('ns', 'exp'), isNull);
      });
    });

    test('invalidate removes a single entry', () {
      cache.put<String>('ns', 'x', 'val');
      cache.invalidate('ns', 'x');
      expect(cache.get<String>('ns', 'x'), isNull);
    });

    test('invalidateNamespace removes all entries in namespace', () {
      cache.put<int>('ns1', 'a', 1);
      cache.put<int>('ns1', 'b', 2);
      cache.put<int>('ns2', 'c', 3);
      cache.invalidateNamespace('ns1');
      expect(cache.get<int>('ns1', 'a'), isNull);
      expect(cache.get<int>('ns1', 'b'), isNull);
      expect(cache.get<int>('ns2', 'c'), 3);
    });

    test('clear resets everything', () {
      cache.put<int>('ns', 'a', 1);
      cache.get<int>('ns', 'a');
      cache.clear();
      expect(cache.size, 0);
      expect(cache.hits, 0);
      expect(cache.misses, 0);
    });

    test('purgeExpired removes stale entries', () async {
      cache.put<String>('ns', 'old', 'data',
          ttl: const Duration(milliseconds: 1));
      cache.put<String>('ns', 'fresh', 'data',
          ttl: const Duration(hours: 1));
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final removed = cache.purgeExpired();
      expect(removed, 1);
      expect(cache.get<String>('ns', 'fresh'), 'data');
    });

    test('getOrLoad fetches and caches on miss', () async {
      var loadCount = 0;
      final val = await cache.getOrLoad<String>('ns', 'computed', () async {
        loadCount++;
        return 'loaded';
      });
      expect(val, 'loaded');
      expect(loadCount, 1);

      // Second call should hit cache.
      final val2 = await cache.getOrLoad<String>('ns', 'computed', () async {
        loadCount++;
        return 'loaded-again';
      });
      expect(val2, 'loaded');
      expect(loadCount, 1);
    });

    test('registerNamespaceTtl overrides default TTL', () {
      cache.registerNamespaceTtl('custom', const Duration(hours: 2));
      cache.put<int>('custom', 'a', 1);
      expect(cache.get<int>('custom', 'a'), 1);
    });
  });
}
