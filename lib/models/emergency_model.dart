
enum EmergencyStatus { active, resolved, cancelled }

enum EmergencyTrigger {
  manual,
  shake,
  voice,
  panic,
  snatch,
  safeWalkTimeout,
  countdown,
}

class EmergencyModel {
  final String emergencyId;
  final String userId;
  final EmergencyStatus status;
  final EmergencyTrigger triggeredBy;
  final double? lat;
  final double? lng;
  final String? audioUrl;
  final String? videoUrl;
  final String? livestreamUrl;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  EmergencyModel({
    required this.emergencyId,
    required this.userId,
    required this.status,
    required this.triggeredBy,
    this.lat,
    this.lng,
    this.audioUrl,
    this.videoUrl,
    this.livestreamUrl,
    required this.createdAt,
    this.resolvedAt,
  });

  // fromMap accepts both snake_case (DB schema) and camelCase (offline cache)
  factory EmergencyModel.fromMap(Map<String, dynamic> data) {
    return EmergencyModel(
      emergencyId: data['id'] ?? data['emergency_id'] ?? '',
      userId: data['user_id'] ?? '',
      status: EmergencyStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => EmergencyStatus.active,
      ),
      triggeredBy: EmergencyTrigger.values.firstWhere(
        (e) => e.name == (data['triggered_by'] ?? data['triggeredBy']),
        orElse: () => EmergencyTrigger.manual,
      ),
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      audioUrl: data['audio_url'] ?? data['audioUrl'],
      videoUrl: data['video_url'] ?? data['videoUrl'],
      livestreamUrl: data['livestream_url'] ?? data['livestreamUrl'],
      createdAt: (data['created_at'] ?? data['createdAt']) != null
          ? DateTime.parse(data['created_at'] ?? data['createdAt'])
          : DateTime.now(),
      resolvedAt: (data['resolved_at'] ?? data['resolvedAt']) != null
          ? DateTime.parse(data['resolved_at'] ?? data['resolvedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'status': status.name,
        'triggered_by': triggeredBy.name,
        'lat': lat,
        'lng': lng,
        'audio_url': audioUrl,
        'video_url': videoUrl,
        'livestream_url': livestreamUrl,
        'created_at': createdAt.toIso8601String(),
        'resolved_at': resolvedAt?.toIso8601String(),
      };

  EmergencyModel copyWith({
    EmergencyStatus? status,
    String? audioUrl,
    String? videoUrl,
    String? livestreamUrl,
    double? lat,
    double? lng,
    DateTime? resolvedAt,
  }) {
    return EmergencyModel(
      emergencyId: emergencyId,
      userId: userId,
      status: status ?? this.status,
      triggeredBy: triggeredBy,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      audioUrl: audioUrl ?? this.audioUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      livestreamUrl: livestreamUrl ?? this.livestreamUrl,
      createdAt: createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
