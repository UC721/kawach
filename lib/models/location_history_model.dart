class LocationHistoryModel {
  final String id;
  final String userId;
  final double lat;
  final double lng;
  final double? accuracy;
  final DateTime recordedAt;

  LocationHistoryModel({
    required this.id,
    required this.userId,
    required this.lat,
    required this.lng,
    this.accuracy,
    required this.recordedAt,
  });

  factory LocationHistoryModel.fromMap(Map<String, dynamic> data) {
    return LocationHistoryModel(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      lat: (data['lat'] as num).toDouble(),
      lng: (data['lng'] as num).toDouble(),
      accuracy: (data['accuracy'] as num?)?.toDouble(),
      recordedAt: data['recordedAt'] != null
          ? DateTime.parse(data['recordedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'lat': lat,
        'lng': lng,
        'accuracy': accuracy,
        'recordedAt': recordedAt.toIso8601String(),
      };
}
