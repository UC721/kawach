class MeshPacketModel {
  const MeshPacketModel({
    required this.packetId,
    required this.emergencyId,
    required this.userId,
    required this.createdAt,
    required this.expiresAt,
    required this.payload,
    this.lat,
    this.lng,
    this.hops = 0,
    this.relaySource = 'supabase',
    this.acknowledged = false,
  });

  final String packetId;
  final String emergencyId;
  final String userId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String payload;
  final double? lat;
  final double? lng;
  final int hops;
  final String relaySource;
  final bool acknowledged;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toMap() {
    return {
      'packet_id': packetId,
      'emergency_id': emergencyId,
      'user_id': userId,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt.toIso8601String(),
      'payload': payload,
      'lat': lat,
      'lng': lng,
      'hops': hops,
      'relay_source': relaySource,
      'acknowledged': acknowledged,
    };
  }

  factory MeshPacketModel.fromMap(Map<String, dynamic> map) {
    return MeshPacketModel(
      packetId: map['packet_id'] ?? map['packetId'] ?? '',
      emergencyId: map['emergency_id'] ?? map['emergencyId'] ?? '',
      userId: map['user_id'] ?? map['userId'] ?? '',
      createdAt: DateTime.parse(
        map['created_at'] ?? map['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      expiresAt: DateTime.parse(
        map['expires_at'] ?? map['expiresAt'] ?? DateTime.now().toIso8601String(),
      ),
      payload: map['payload'] ?? '',
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      hops: map['hops'] ?? 0,
      relaySource: map['relay_source'] ?? map['relaySource'] ?? 'supabase',
      acknowledged: map['acknowledged'] ?? false,
    );
  }
}
