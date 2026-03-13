
class EvidenceModel {
  final String evidenceId;
  final String userId;
  final String emergencyId;
  final String? audioUrl;
  final String? videoUrl;
  final double? lat;
  final double? lng;
  final DateTime timestamp;

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

  factory EvidenceModel.fromMap(Map<String, dynamic> data) {
    return EvidenceModel(
      evidenceId: data['evidenceId'] ?? '',
      userId: data['userId'] ?? '',
      emergencyId: data['emergencyId'] ?? '',
      audioUrl: data['audioUrl'],
      videoUrl: data['videoUrl'],
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      timestamp: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'emergencyId': emergencyId,
        'audioUrl': audioUrl,
        'videoUrl': videoUrl,
        'lat': lat,
        'lng': lng,
        'timestamp': timestamp.toIso8601String(),
      };
}
