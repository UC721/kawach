class NearbyAlertModel {
  const NearbyAlertModel({
    required this.alertId,
    required this.emergencyId,
    required this.userId,
    required this.createdAt,
    required this.status,
    this.lat,
    this.lng,
    this.distanceMeters,
    this.userName,
  });

  final String alertId;
  final String emergencyId;
  final String userId;
  final DateTime createdAt;
  final String status;
  final double? lat;
  final double? lng;
  final double? distanceMeters;
  final String? userName;

  bool get isActive => status != 'resolved' && status != 'cancelled';

  factory NearbyAlertModel.fromMap(Map<String, dynamic> map) {
    return NearbyAlertModel(
      alertId: map['alert_id'] ?? map['id'] ?? '',
      emergencyId: map['emergency_id'] ?? map['emergencyId'] ?? '',
      userId: map['user_id'] ?? map['userId'] ?? '',
      createdAt: DateTime.parse(
        map['created_at'] ?? map['sent_at'] ?? DateTime.now().toIso8601String(),
      ),
      status: map['status'] ?? 'pending',
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      distanceMeters: (map['distance_meters'] as num?)?.toDouble(),
      userName: (map['user_name'] ?? map['userName']) as String?,
    );
  }
}
