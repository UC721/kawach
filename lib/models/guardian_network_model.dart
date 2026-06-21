class GuardianNetworkModel {
  GuardianNetworkModel({
    required this.volunteerId,
    required this.userId,
    required this.name,
    this.lat,
    this.lng,
    required this.verified,
    required this.availability,
    this.phone,
    this.lastSeen,
  });

  final String volunteerId;
  final String userId;
  final String name;
  final double? lat;
  final double? lng;
  final bool verified;
  final bool availability;
  final String? phone;
  final DateTime? lastSeen;

  factory GuardianNetworkModel.fromMap(Map<String, dynamic> data) {
    return GuardianNetworkModel(
      volunteerId: data['volunteer_id'] ?? data['volunteerId'] ?? '',
      userId: data['user_id'] ?? data['userId'] ?? '',
      name: data['name'] ?? '',
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      verified: data['verified'] ?? false,
      availability: data['availability'] ?? false,
      phone: data['phone'] as String?,
      lastSeen: data['last_seen'] != null
          ? DateTime.parse(data['last_seen'] as String)
          : data['lastSeen'] != null
              ? DateTime.parse(data['lastSeen'] as String)
              : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'volunteer_id': volunteerId,
      'user_id': userId,
      'name': name,
      'lat': lat,
      'lng': lng,
      'verified': verified,
      'availability': availability,
      'phone': phone,
      'last_seen': lastSeen?.toIso8601String(),
    };
  }
}
