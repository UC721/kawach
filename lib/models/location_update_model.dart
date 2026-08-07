class LocationUpdateModel {
  const LocationUpdateModel({
    required this.emergencyId,
    required this.userId,
    required this.lat,
    required this.lng,
    required this.recordedAt,
    this.speed,
    this.heading,
    this.accuracy,
    this.encryptedPayload,
    this.source = 'device',
  });

  final String emergencyId;
  final String userId;
  final double lat;
  final double lng;
  final DateTime recordedAt;
  final double? speed;
  final double? heading;
  final double? accuracy;
  final String? encryptedPayload;
  final String source;

  Map<String, dynamic> toMap() {
    return {
      'emergency_id': emergencyId,
      'user_id': userId,
      'lat': lat,
      'lng': lng,
      'speed': speed,
      'heading': heading,
      'accuracy': accuracy,
      'source': source,
      'recorded_at': recordedAt.toIso8601String(),
      'encrypted_payload': encryptedPayload,
    };
  }

  factory LocationUpdateModel.fromMap(Map<String, dynamic> map) {
    return LocationUpdateModel(
      emergencyId: map['emergency_id'] ?? map['emergencyId'] ?? '',
      userId: map['user_id'] ?? map['userId'] ?? '',
      lat: (map['lat'] as num).toDouble(),
      lng: (map['lng'] as num).toDouble(),
      speed: (map['speed'] as num?)?.toDouble(),
      heading: (map['heading'] as num?)?.toDouble(),
      accuracy: (map['accuracy'] as num?)?.toDouble(),
      source: map['source'] ?? 'device',
      encryptedPayload:
          (map['encrypted_payload'] ?? map['encryptedPayload']) as String?,
      recordedAt: DateTime.parse(
        map['recorded_at'] ??
            map['recordedAt'] ??
            DateTime.now().toIso8601String(),
      ),
    );
  }
}
