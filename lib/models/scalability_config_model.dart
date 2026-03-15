/// Configuration model for KAWACH scalability settings.
///
/// Centralises tuning knobs for cache, rate-limiting, batching,
/// circuit-breaker, and real-time channel management so that every
/// scalability service reads from one source of truth.
class ScalabilityConfig {
  // ── Cache ──────────────────────────────────────────────────
  /// Maximum number of items kept in the in-memory LRU cache.
  final int memoryCacheMaxItems;

  /// Default time-to-live for cached entries.
  final Duration cacheTtl;

  /// TTL for user-profile entries (accessed very frequently).
  final Duration userProfileCacheTtl;

  /// TTL for danger-zone data (changes infrequently).
  final Duration dangerZoneCacheTtl;

  // ── Rate-limiting ──────────────────────────────────────────
  /// Maximum number of tokens in the rate-limiter bucket.
  final int rateLimitMaxTokens;

  /// How quickly tokens are refilled.
  final Duration rateLimitRefillInterval;

  /// Number of tokens added per refill cycle.
  final int rateLimitTokensPerRefill;

  // ── Batching ───────────────────────────────────────────────
  /// Maximum number of operations queued before a flush is forced.
  final int batchMaxSize;

  /// Maximum time to wait before flushing a non-full batch.
  final Duration batchFlushInterval;

  /// Maximum number of retries for a failed batch.
  final int batchMaxRetries;

  // ── Circuit-breaker ────────────────────────────────────────
  /// Number of consecutive failures before opening the circuit.
  final int circuitBreakerFailureThreshold;

  /// How long to wait in the *open* state before attempting a reset.
  final Duration circuitBreakerResetTimeout;

  /// Number of successful probe requests required to *close* the
  /// circuit again (half-open → closed).
  final int circuitBreakerSuccessThreshold;

  // ── Real-time channels ─────────────────────────────────────
  /// Maximum number of Supabase Realtime channels open at once.
  final int maxRealtimeChannels;

  /// How long an idle channel stays open before it is auto-closed.
  final Duration channelIdleTimeout;

  /// Delay before attempting to reconnect a dropped channel.
  final Duration channelReconnectDelay;

  // ── Request de-duplication ─────────────────────────────────
  /// Window within which duplicate request keys are suppressed.
  final Duration deduplicationWindow;

  // ── Connection pool ────────────────────────────────────────
  /// Interval between automatic health-check pings.
  final Duration healthCheckInterval;

  /// Maximum number of consecutive health-check failures before
  /// the pool is recycled.
  final int maxHealthCheckFailures;

  const ScalabilityConfig({
    this.memoryCacheMaxItems = 1000,
    this.cacheTtl = const Duration(minutes: 5),
    this.userProfileCacheTtl = const Duration(minutes: 10),
    this.dangerZoneCacheTtl = const Duration(minutes: 30),
    this.rateLimitMaxTokens = 60,
    this.rateLimitRefillInterval = const Duration(seconds: 1),
    this.rateLimitTokensPerRefill = 1,
    this.batchMaxSize = 50,
    this.batchFlushInterval = const Duration(seconds: 5),
    this.batchMaxRetries = 3,
    this.circuitBreakerFailureThreshold = 5,
    this.circuitBreakerResetTimeout = const Duration(seconds: 30),
    this.circuitBreakerSuccessThreshold = 2,
    this.maxRealtimeChannels = 10,
    this.channelIdleTimeout = const Duration(minutes: 5),
    this.channelReconnectDelay = const Duration(seconds: 3),
    this.deduplicationWindow = const Duration(seconds: 10),
    this.healthCheckInterval = const Duration(seconds: 30),
    this.maxHealthCheckFailures = 3,
  });

  /// Sensible defaults for production at scale.
  factory ScalabilityConfig.production() => const ScalabilityConfig(
        memoryCacheMaxItems: 5000,
        cacheTtl: Duration(minutes: 10),
        userProfileCacheTtl: Duration(minutes: 15),
        dangerZoneCacheTtl: Duration(hours: 1),
        rateLimitMaxTokens: 120,
        rateLimitRefillInterval: Duration(seconds: 1),
        rateLimitTokensPerRefill: 2,
        batchMaxSize: 100,
        batchFlushInterval: Duration(seconds: 3),
        batchMaxRetries: 5,
        circuitBreakerFailureThreshold: 10,
        circuitBreakerResetTimeout: Duration(seconds: 60),
        circuitBreakerSuccessThreshold: 3,
        maxRealtimeChannels: 20,
        channelIdleTimeout: Duration(minutes: 10),
        channelReconnectDelay: Duration(seconds: 5),
        deduplicationWindow: Duration(seconds: 15),
        healthCheckInterval: Duration(seconds: 60),
        maxHealthCheckFailures: 5,
      );

  ScalabilityConfig copyWith({
    int? memoryCacheMaxItems,
    Duration? cacheTtl,
    Duration? userProfileCacheTtl,
    Duration? dangerZoneCacheTtl,
    int? rateLimitMaxTokens,
    Duration? rateLimitRefillInterval,
    int? rateLimitTokensPerRefill,
    int? batchMaxSize,
    Duration? batchFlushInterval,
    int? batchMaxRetries,
    int? circuitBreakerFailureThreshold,
    Duration? circuitBreakerResetTimeout,
    int? circuitBreakerSuccessThreshold,
    int? maxRealtimeChannels,
    Duration? channelIdleTimeout,
    Duration? channelReconnectDelay,
    Duration? deduplicationWindow,
    Duration? healthCheckInterval,
    int? maxHealthCheckFailures,
  }) {
    return ScalabilityConfig(
      memoryCacheMaxItems:
          memoryCacheMaxItems ?? this.memoryCacheMaxItems,
      cacheTtl: cacheTtl ?? this.cacheTtl,
      userProfileCacheTtl:
          userProfileCacheTtl ?? this.userProfileCacheTtl,
      dangerZoneCacheTtl:
          dangerZoneCacheTtl ?? this.dangerZoneCacheTtl,
      rateLimitMaxTokens:
          rateLimitMaxTokens ?? this.rateLimitMaxTokens,
      rateLimitRefillInterval:
          rateLimitRefillInterval ?? this.rateLimitRefillInterval,
      rateLimitTokensPerRefill:
          rateLimitTokensPerRefill ?? this.rateLimitTokensPerRefill,
      batchMaxSize: batchMaxSize ?? this.batchMaxSize,
      batchFlushInterval:
          batchFlushInterval ?? this.batchFlushInterval,
      batchMaxRetries: batchMaxRetries ?? this.batchMaxRetries,
      circuitBreakerFailureThreshold: circuitBreakerFailureThreshold ??
          this.circuitBreakerFailureThreshold,
      circuitBreakerResetTimeout:
          circuitBreakerResetTimeout ?? this.circuitBreakerResetTimeout,
      circuitBreakerSuccessThreshold: circuitBreakerSuccessThreshold ??
          this.circuitBreakerSuccessThreshold,
      maxRealtimeChannels:
          maxRealtimeChannels ?? this.maxRealtimeChannels,
      channelIdleTimeout:
          channelIdleTimeout ?? this.channelIdleTimeout,
      channelReconnectDelay:
          channelReconnectDelay ?? this.channelReconnectDelay,
      deduplicationWindow:
          deduplicationWindow ?? this.deduplicationWindow,
      healthCheckInterval:
          healthCheckInterval ?? this.healthCheckInterval,
      maxHealthCheckFailures:
          maxHealthCheckFailures ?? this.maxHealthCheckFailures,
    );
  }

  Map<String, dynamic> toMap() => {
        'memoryCacheMaxItems': memoryCacheMaxItems,
        'cacheTtlMs': cacheTtl.inMilliseconds,
        'userProfileCacheTtlMs': userProfileCacheTtl.inMilliseconds,
        'dangerZoneCacheTtlMs': dangerZoneCacheTtl.inMilliseconds,
        'rateLimitMaxTokens': rateLimitMaxTokens,
        'rateLimitRefillIntervalMs':
            rateLimitRefillInterval.inMilliseconds,
        'rateLimitTokensPerRefill': rateLimitTokensPerRefill,
        'batchMaxSize': batchMaxSize,
        'batchFlushIntervalMs': batchFlushInterval.inMilliseconds,
        'batchMaxRetries': batchMaxRetries,
        'circuitBreakerFailureThreshold': circuitBreakerFailureThreshold,
        'circuitBreakerResetTimeoutMs':
            circuitBreakerResetTimeout.inMilliseconds,
        'circuitBreakerSuccessThreshold': circuitBreakerSuccessThreshold,
        'maxRealtimeChannels': maxRealtimeChannels,
        'channelIdleTimeoutMs': channelIdleTimeout.inMilliseconds,
        'channelReconnectDelayMs':
            channelReconnectDelay.inMilliseconds,
        'deduplicationWindowMs': deduplicationWindow.inMilliseconds,
        'healthCheckIntervalMs': healthCheckInterval.inMilliseconds,
        'maxHealthCheckFailures': maxHealthCheckFailures,
      };

  factory ScalabilityConfig.fromMap(Map<String, dynamic> map) {
    return ScalabilityConfig(
      memoryCacheMaxItems: map['memoryCacheMaxItems'] as int? ?? 1000,
      cacheTtl: Duration(
          milliseconds: map['cacheTtlMs'] as int? ?? 300000),
      userProfileCacheTtl: Duration(
          milliseconds:
              map['userProfileCacheTtlMs'] as int? ?? 600000),
      dangerZoneCacheTtl: Duration(
          milliseconds:
              map['dangerZoneCacheTtlMs'] as int? ?? 1800000),
      rateLimitMaxTokens: map['rateLimitMaxTokens'] as int? ?? 60,
      rateLimitRefillInterval: Duration(
          milliseconds:
              map['rateLimitRefillIntervalMs'] as int? ?? 1000),
      rateLimitTokensPerRefill:
          map['rateLimitTokensPerRefill'] as int? ?? 1,
      batchMaxSize: map['batchMaxSize'] as int? ?? 50,
      batchFlushInterval: Duration(
          milliseconds:
              map['batchFlushIntervalMs'] as int? ?? 5000),
      batchMaxRetries: map['batchMaxRetries'] as int? ?? 3,
      circuitBreakerFailureThreshold:
          map['circuitBreakerFailureThreshold'] as int? ?? 5,
      circuitBreakerResetTimeout: Duration(
          milliseconds:
              map['circuitBreakerResetTimeoutMs'] as int? ?? 30000),
      circuitBreakerSuccessThreshold:
          map['circuitBreakerSuccessThreshold'] as int? ?? 2,
      maxRealtimeChannels:
          map['maxRealtimeChannels'] as int? ?? 10,
      channelIdleTimeout: Duration(
          milliseconds:
              map['channelIdleTimeoutMs'] as int? ?? 300000),
      channelReconnectDelay: Duration(
          milliseconds:
              map['channelReconnectDelayMs'] as int? ?? 3000),
      deduplicationWindow: Duration(
          milliseconds:
              map['deduplicationWindowMs'] as int? ?? 10000),
      healthCheckInterval: Duration(
          milliseconds:
              map['healthCheckIntervalMs'] as int? ?? 30000),
      maxHealthCheckFailures:
          map['maxHealthCheckFailures'] as int? ?? 3,
    );
  }
}
