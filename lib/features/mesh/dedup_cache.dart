// ============================================================
// DedupCache – TTL-based message deduplication (bloom filter)
// ============================================================

/// Prevents duplicate message relay in mesh networks.
///
/// Uses a simple time-to-live cache to track recently seen message IDs.
/// Entries expire after [ttlSeconds] to bound memory usage.
class DedupCache {
  final int ttlSeconds;
  final Map<String, DateTime> _entries = {};

  DedupCache({this.ttlSeconds = 300});

  /// Check whether [messageId] has been seen recently.
  bool contains(String messageId) {
    _evictExpired();
    return _entries.containsKey(messageId);
  }

  /// Record [messageId] as seen.
  void add(String messageId) {
    _evictExpired();
    _entries[messageId] = DateTime.now();
  }

  /// Remove an entry manually (e.g. on explicit cancellation).
  void remove(String messageId) {
    _entries.remove(messageId);
  }

  /// Number of currently tracked entries.
  int get size {
    _evictExpired();
    return _entries.length;
  }

  /// Clear all entries.
  void clear() => _entries.clear();

  void _evictExpired() {
    final cutoff = DateTime.now().subtract(Duration(seconds: ttlSeconds));
    _entries.removeWhere((_, timestamp) => timestamp.isBefore(cutoff));
  }
}
