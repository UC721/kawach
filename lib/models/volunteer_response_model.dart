class VolunteerResponseModel {
  final String id;
  final String volunteerId;
  final String emergencyId;
  final String userId;
  final String status;
  final DateTime? respondedAt;
  final DateTime? arrivedAt;
  final double? lat;
  final double? lng;
  final DateTime createdAt;

  VolunteerResponseModel({
    required this.id,
    required this.volunteerId,
    required this.emergencyId,
    required this.userId,
    this.status = 'pending',
    this.respondedAt,
    this.arrivedAt,
    this.lat,
    this.lng,
    required this.createdAt,
  });

  factory VolunteerResponseModel.fromMap(Map<String, dynamic> data) {
    return VolunteerResponseModel(
      id: data['id'] ?? '',
      volunteerId: data['volunteerId'] ?? '',
      emergencyId: data['emergencyId'] ?? '',
      userId: data['userId'] ?? '',
      status: data['status'] ?? 'pending',
      respondedAt: data['respondedAt'] != null
          ? DateTime.parse(data['respondedAt'])
          : null,
      arrivedAt: data['arrivedAt'] != null
          ? DateTime.parse(data['arrivedAt'])
          : null,
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'volunteerId': volunteerId,
        'emergencyId': emergencyId,
        'userId': userId,
        'status': status,
        'respondedAt': respondedAt?.toIso8601String(),
        'arrivedAt': arrivedAt?.toIso8601String(),
        'lat': lat,
        'lng': lng,
        'createdAt': createdAt.toIso8601String(),
      };
}
