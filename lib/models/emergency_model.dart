
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

  factory EmergencyModel.fromMap(Map<String, dynamic> data) {
    return EmergencyModel(
      emergencyId: data['id'] ?? data['emergencyId'] ?? data['emergency_id'] ?? '',
      userId: data['userId'] ?? data['user_id'] ?? '',
      status: EmergencyStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => EmergencyStatus.active,
      ),
      triggeredBy: EmergencyTrigger.values.firstWhere(
        (e) => e.name == (data['triggeredBy'] ?? data['triggered_by']),
        orElse: () => EmergencyTrigger.manual,
      ),
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      audioUrl: data['audioUrl'] ?? data['audio_url'],
      videoUrl: data['videoUrl'] ?? data['video_url'],
      livestreamUrl: data['livestreamUrl'] ?? data['livestream_url'],
      createdAt: (data['createdAt'] ?? data['created_at']) != null
          ? DateTime.parse(data['createdAt'] ?? data['created_at'])
          : DateTime.now(),
      resolvedAt: (data['resolvedAt'] ?? data['resolved_at']) != null
          ? DateTime.parse(data['resolvedAt'] ?? data['resolved_at'])
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
