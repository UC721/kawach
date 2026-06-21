class EvidenceModel {
  EvidenceModel({
    required this.evidenceId,
    required this.userId,
    required this.emergencyId,
    this.audioUrl,
    this.videoUrl,
    this.lat,
    this.lng,
    required this.timestamp,
  });

  final String evidenceId;
  final String userId;
  final String emergencyId;
  final String? audioUrl;
  final String? videoUrl;
  final double? lat;
  final double? lng;
  final DateTime timestamp;

  factory EvidenceModel.fromMap(Map<String, dynamic> data) {
    return EvidenceModel(
      evidenceId: data['evidence_id'] ?? data['evidenceId'] ?? '',
      userId: data['user_id'] ?? data['userId'] ?? '',
      emergencyId: data['emergency_id'] ?? data['emergencyId'] ?? '',
      audioUrl: (data['audio_url'] ?? data['audioUrl']) as String?,
      videoUrl: (data['video_url'] ?? data['videoUrl']) as String?,
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      timestamp: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'evidence_id': evidenceId,
      'user_id': userId,
      'emergency_id': emergencyId,
      'audio_url': audioUrl,
      'video_url': videoUrl,
      'lat': lat,
      'lng': lng,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
