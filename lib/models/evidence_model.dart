
class EvidenceModel {
  final String evidenceId;
  final String userId;
  final String emergencyId;
  final String? audioUrl;
  final String? videoUrl;
  final String? storagePath;
  final String? type;
  final bool encrypted;
  final double? lat;
  final double? lng;
  final DateTime timestamp;

  EvidenceModel({
    required this.evidenceId,
    required this.userId,
    required this.emergencyId,
    this.audioUrl,
    this.videoUrl,
    this.storagePath,
    this.type,
    this.encrypted = true,
    this.lat,
    this.lng,
    required this.timestamp,
  });

  factory EvidenceModel.fromMap(Map<String, dynamic> data) {
    return EvidenceModel(
      evidenceId: (data['id'] ?? data['evidenceId'] ?? data['evidence_id'] ?? '').toString(),
      userId: (data['user_id'] ?? data['userId'] ?? '').toString(),
      emergencyId: (data['sos_alert_id'] ?? data['emergencyId'] ?? data['emergency_id'] ?? '').toString(),
      audioUrl: data['audio_url'] ?? data['audioUrl'],
      videoUrl: data['video_url'] ?? data['videoUrl'],
      storagePath: data['storage_path'] ?? data['storagePath'],
      type: data['type'],
      encrypted: data['encrypted'] ?? true,
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      timestamp: (data['created_at'] ?? data['timestamp']) != null
          ? DateTime.parse(data['created_at'] ?? data['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'sos_alert_id': emergencyId,
        'type': type ?? (videoUrl != null ? 'video' : 'audio'),
        'storage_path': storagePath ?? audioUrl ?? videoUrl ?? '',
        'encrypted': encrypted,
        'lat': lat,
        'lng': lng,
      };
}
