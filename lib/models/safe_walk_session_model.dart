class SafeWalkSessionModel {
  final String id;
  final String userId;
  final String? guardianId;
  final String status;
  final double? startLat;
  final double? startLng;
  final double? destLat;
  final double? destLng;
  final int durationSeconds;
  final DateTime startedAt;
  final DateTime? endedAt;
  final DateTime createdAt;

  SafeWalkSessionModel({
    required this.id,
    required this.userId,
    this.guardianId,
    this.status = 'active',
    this.startLat,
    this.startLng,
    this.destLat,
    this.destLng,
    this.durationSeconds = 1800,
    required this.startedAt,
    this.endedAt,
    required this.createdAt,
  });

  factory SafeWalkSessionModel.fromMap(Map<String, dynamic> data) {
    return SafeWalkSessionModel(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      guardianId: data['guardianId'],
      status: data['status'] ?? 'active',
      startLat: (data['startLat'] as num?)?.toDouble(),
      startLng: (data['startLng'] as num?)?.toDouble(),
      destLat: (data['destLat'] as num?)?.toDouble(),
      destLng: (data['destLng'] as num?)?.toDouble(),
      durationSeconds: data['durationSeconds'] ?? 1800,
      startedAt: data['startedAt'] != null
          ? DateTime.parse(data['startedAt'])
          : DateTime.now(),
      endedAt: data['endedAt'] != null
          ? DateTime.parse(data['endedAt'])
          : null,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'guardianId': guardianId,
        'status': status,
        'startLat': startLat,
        'startLng': startLng,
        'destLat': destLat,
        'destLng': destLng,
        'durationSeconds': durationSeconds,
        'startedAt': startedAt.toIso8601String(),
        'endedAt': endedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  SafeWalkSessionModel copyWith({
    String? status,
    DateTime? endedAt,
  }) {
    return SafeWalkSessionModel(
      id: id,
      userId: userId,
      guardianId: guardianId,
      status: status ?? this.status,
      startLat: startLat,
      startLng: startLng,
      destLat: destLat,
      destLng: destLng,
      durationSeconds: durationSeconds,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      createdAt: createdAt,
    );
  }
}
