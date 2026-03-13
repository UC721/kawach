
class GuardianNetworkModel {
  final String volunteerId;
  final String userId; // volunteer's user account
  final String name;
  final double? lat;
  final double? lng;
  final bool verified;
  final bool availability;
  final String? phone;
  final DateTime? lastSeen;

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

  factory GuardianNetworkModel.fromMap(Map<String, dynamic> data) {
    return GuardianNetworkModel(
      volunteerId: data['volunteerId'] ?? '',
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      verified: data['verified'] ?? false,
      availability: data['availability'] ?? false,
      phone: data['phone'],
      lastSeen: data['lastSeen'] != null ? DateTime.parse(data['lastSeen']) : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'lat': lat,
        'lng': lng,
        'verified': verified,
        'availability': availability,
        'phone': phone,
        'lastSeen': lastSeen?.toIso8601String(),
      };
}
