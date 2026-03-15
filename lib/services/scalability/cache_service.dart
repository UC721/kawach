import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../models/scalability_config_model.dart';

/// A single cache entry with value and expiration time.
class _CacheEntry<T> {
  final T value;
  final DateTime expiresAt;

  _CacheEntry(this.value, this.expiresAt);

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Multi-tier in-memory LRU cache designed for millions of users.
///
/// Provides namespace-based caching so that user profiles, danger
/// zones, guardian data, and other frequently-accessed entities are
/// served from memory and avoid unnecessary network round-trips.
///
/// The cache uses an LRU eviction strategy: when the maximum number
/// of entries is exceeded, the least-recently-used entry is removed.
class CacheService extends ChangeNotifier {
  final ScalabilityConfig _config;

  /// Backing store: namespace:key → entry.
  final LinkedHashMap<String, _CacheEntry<dynamic>> _store =
      LinkedHashMap<String, _CacheEntry<dynamic>>();

  /// Per-namespace TTL overrides.
  final Map<String, Duration> _namespaceTtl = {};

  /// Cache hit / miss statistics.
  int _hits = 0;
  int _misses = 0;

  int get hits => _hits;
  int get misses => _misses;
  int get size => _store.length;
  double get hitRate =>
      (_hits + _misses) == 0 ? 0.0 : _hits / (_hits + _misses);

  CacheService({ScalabilityConfig? config})
      : _config = config ?? const ScalabilityConfig() {
    // Register built-in namespace TTLs.
    _namespaceTtl['user_profile'] = _config.userProfileCacheTtl;
    _namespaceTtl['danger_zone'] = _config.dangerZoneCacheTtl;
  }

  /// Register a custom TTL for a given [namespace].
  void registerNamespaceTtl(String namespace, Duration ttl) {
    _namespaceTtl[namespace] = ttl;
  }

  /// Resolve the effective TTL for [namespace].
  Duration _ttlFor(String namespace) =>
      _namespaceTtl[namespace] ?? _config.cacheTtl;

  /// Full cache key.
  String _fullKey(String namespace, String key) => '$namespace:$key';

  /// Store [value] under [namespace]:[key].
  void put<T>(String namespace, String key, T value, {Duration? ttl}) {
    final fk = _fullKey(namespace, key);
    final effectiveTtl = ttl ?? _ttlFor(namespace);
    final entry = _CacheEntry<T>(
      value,
      DateTime.now().add(effectiveTtl),
    );

    // Remove first so reinsertion moves to the end (most-recently-used).
    _store.remove(fk);
    _store[fk] = entry;
    _evictIfNeeded();
  }

  /// Retrieve a cached value, or `null` if absent or expired.
  T? get<T>(String namespace, String key) {
    final fk = _fullKey(namespace, key);
    final entry = _store[fk];
    if (entry == null || entry.isExpired) {
      if (entry != null) _store.remove(fk); // lazy expiration
      _misses++;
      return null;
    }

    // Move to end (most-recently-used).
    _store.remove(fk);
    _store[fk] = entry;
    _hits++;
    return entry.value as T;
  }

  /// Remove a single entry.
  void invalidate(String namespace, String key) {
    _store.remove(_fullKey(namespace, key));
  }

  /// Remove all entries for a namespace.
  void invalidateNamespace(String namespace) {
    _store.removeWhere((k, _) => k.startsWith('$namespace:'));
  }

  /// Remove all entries.
  void clear() {
    _store.clear();
    _hits = 0;
    _misses = 0;
    notifyListeners();
  }

  /// Evict the least-recently-used entries until within the limit.
  void _evictIfNeeded() {
    while (_store.length > _config.memoryCacheMaxItems) {
      _store.remove(_store.keys.first);
    }
  }

  /// Remove all expired entries (can be called periodically).
  int purgeExpired() {
    final expired = <String>[];
    for (final entry in _store.entries) {
      if (entry.value.isExpired) expired.add(entry.key);
    }
    for (final key in expired) {
      _store.remove(key);
    }
    return expired.length;
  }

  /// Fetch-or-compute pattern: return cached value or call [loader],
  /// cache the result, and return it.
  Future<T> getOrLoad<T>(
    String namespace,
    String key,
    Future<T> Function() loader, {
    Duration? ttl,
  }) async {
    final cached = get<T>(namespace, key);
    if (cached != null) return cached;

    final value = await loader();
    put<T>(namespace, key, value, ttl: ttl);
    return value;
  }
}
