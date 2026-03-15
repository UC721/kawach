import '../../models/scalability_config_model.dart';

/// Token-bucket rate limiter.
///
/// Each named bucket starts with [maxTokens] tokens. Every request
/// consumes one token; tokens are refilled at a fixed rate.  When a
/// bucket is empty the request is rejected, protecting the Supabase
/// backend from client-generated traffic spikes.
class RateLimiter {
  final ScalabilityConfig _config;

  /// Per-bucket state: bucket name → _Bucket.
  final Map<String, _Bucket> _buckets = {};

  RateLimiter({ScalabilityConfig? config})
      : _config = config ?? const ScalabilityConfig();

  /// Try to consume one token from [bucketName].
  ///
  /// Returns `true` if the request is allowed, `false` otherwise.
  bool tryAcquire(String bucketName) {
    final bucket = _buckets.putIfAbsent(
      bucketName,
      () => _Bucket(
        maxTokens: _config.rateLimitMaxTokens,
        refillInterval: _config.rateLimitRefillInterval,
        tokensPerRefill: _config.rateLimitTokensPerRefill,
      ),
    );
    return bucket.tryConsume();
  }

  /// Number of tokens currently available in [bucketName].
  int availableTokens(String bucketName) {
    final bucket = _buckets[bucketName];
    if (bucket == null) return _config.rateLimitMaxTokens;
    bucket.refill();
    return bucket.tokens;
  }

  /// Reset a specific bucket.
  void resetBucket(String bucketName) {
    _buckets.remove(bucketName);
  }

  /// Reset all buckets.
  void resetAll() {
    _buckets.clear();
  }
}

class _Bucket {
  final int maxTokens;
  final Duration refillInterval;
  final int tokensPerRefill;
  int tokens;
  DateTime _lastRefill;

  _Bucket({
    required this.maxTokens,
    required this.refillInterval,
    required this.tokensPerRefill,
  })  : tokens = maxTokens,
        _lastRefill = DateTime.now();

  void refill() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastRefill);
    if (elapsed >= refillInterval) {
      final periods = elapsed.inMilliseconds ~/ refillInterval.inMilliseconds;
      tokens = (tokens + periods * tokensPerRefill).clamp(0, maxTokens);
      _lastRefill = now;
    }
  }

  bool tryConsume() {
    refill();
    if (tokens > 0) {
      tokens--;
      return true;
    }
    return false;
  }
}
