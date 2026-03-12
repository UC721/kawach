import 'package:cloud_firestore/cloud_firestore.dart';

class EvidenceModel {
  final String evidenceId;
  final String userId;
  final String emergencyId;
  final String? audioUrl;
  final String? videoUrl;
  final GeoPoint? location;
  final DateTime timestamp;

  EvidenceModel({
    required this.evidenceId,
    required this.userId,
    required this.emergencyId,
    this.audioUrl,
    this.videoUrl,
    this.location,
    required this.timestamp,
  });

  factory EvidenceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EvidenceModel(
      evidenceId: doc.id,
      userId: data['userId'] ?? '',
      emergencyId: data['emergencyId'] ?? '',
      audioUrl: data['audioUrl'],
      videoUrl: data['videoUrl'],
      location: data['location'] as GeoPoint?,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'emergencyId': emergencyId,
        'audioUrl': audioUrl,
        'videoUrl': videoUrl,
        'location': location,
        'timestamp': Timestamp.fromDate(timestamp),
      };
}
