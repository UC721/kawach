/// Message types supported by the KAWACH mesh protocol.
enum MeshMessageType {
  /// SOS / emergency broadcast.
  emergency,

  /// Acknowledgement that a gateway has received the message.
  ack,

  /// Periodic heartbeat for peer discovery.
  heartbeat,

  /// Generic relay payload (e.g. location update).
  relay,
}

/// A single message propagated through the KAWACH mesh network.
///
/// Every message carries a UUID for deduplication, a TTL to limit its
/// lifetime, and a hop counter that is incremented at each relay.
class MeshMessageModel {
  /// Unique identifier (UUID v4) used for deduplication.
  final String messageId;

  /// Device / user ID of the original sender.
  final String senderId;

  /// Semantic type of this message.
  final MeshMessageType type;

  /// Encrypted payload encoded as a Base-64 string.
  final String payload;

  /// Remaining time-to-live in **seconds**. Decremented at each hop.
  final int ttlSeconds;

  /// Number of hops this message has traversed so far.
  final int hopCount;

  /// Maximum number of hops allowed before the message is dropped.
  final int maxHops;

  /// Timestamp when the message was originally created.
  final DateTime createdAt;

  /// Absolute expiry time (`createdAt + initial TTL`).
  final DateTime expiresAt;

  MeshMessageModel({
    required this.messageId,
    required this.senderId,
    required this.type,
    required this.payload,
    required this.ttlSeconds,
    this.hopCount = 0,
    this.maxHops = 10,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Whether this message has exceeded its TTL.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Whether this message has exhausted its hop budget.
  bool get isMaxHopsReached => hopCount >= maxHops;

  /// Composite key used for bloom-filter deduplication.
  String get deduplicationKey => '$messageId:${createdAt.millisecondsSinceEpoch}';

  // ── Serialisation ──────────────────────────────────────────────

  factory MeshMessageModel.fromMap(Map<String, dynamic> data) {
    return MeshMessageModel(
      messageId: data['message_id'] ?? '',
      senderId: data['sender_id'] ?? '',
      type: MeshMessageType.values.firstWhere(
        (e) => e.name == data['type'],
        orElse: () => MeshMessageType.relay,
      ),
      payload: data['payload'] ?? '',
      ttlSeconds: data['ttl_seconds'] ?? 0,
      hopCount: data['hop_count'] ?? 0,
      maxHops: data['max_hops'] ?? 10,
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : DateTime.now(),
      expiresAt: data['expires_at'] != null
          ? DateTime.parse(data['expires_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'message_id': messageId,
        'sender_id': senderId,
        'type': type.name,
        'payload': payload,
        'ttl_seconds': ttlSeconds,
        'hop_count': hopCount,
        'max_hops': maxHops,
        'created_at': createdAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
      };

  MeshMessageModel copyWith({
    String? payload,
    int? ttlSeconds,
    int? hopCount,
    int? maxHops,
    MeshMessageType? type,
  }) {
    return MeshMessageModel(
      messageId: messageId,
      senderId: senderId,
      type: type ?? this.type,
      payload: payload ?? this.payload,
      ttlSeconds: ttlSeconds ?? this.ttlSeconds,
      hopCount: hopCount ?? this.hopCount,
      maxHops: maxHops ?? this.maxHops,
      createdAt: createdAt,
      expiresAt: expiresAt,
    );
  }

  @override
  String toString() =>
      'MeshMessage(id=$messageId, type=${type.name}, hops=$hopCount/$maxHops, '
      'ttl=${ttlSeconds}s, expired=$isExpired)';
}
