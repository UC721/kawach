import 'package:cloud_firestore/cloud_firestore.dart';

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
  final GeoPoint? location;
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
    this.location,
    this.audioUrl,
    this.videoUrl,
    this.livestreamUrl,
    required this.createdAt,
    this.resolvedAt,
  });

  factory EmergencyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return EmergencyModel(
      emergencyId: doc.id,
      userId: data['userId'] ?? '',
      status: EmergencyStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => EmergencyStatus.active,
      ),
      triggeredBy: EmergencyTrigger.values.firstWhere(
        (e) => e.name == data['triggeredBy'],
        orElse: () => EmergencyTrigger.manual,
      ),
      location: data['location'] as GeoPoint?,
      audioUrl: data['audioUrl'],
      videoUrl: data['videoUrl'],
      livestreamUrl: data['livestreamUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (data['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'status': status.name,
        'triggeredBy': triggeredBy.name,
        'location': location,
        'audioUrl': audioUrl,
        'videoUrl': videoUrl,
        'livestreamUrl': livestreamUrl,
        'createdAt': Timestamp.fromDate(createdAt),
        'resolvedAt':
            resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      };

  EmergencyModel copyWith({
    EmergencyStatus? status,
    String? audioUrl,
    String? videoUrl,
    String? livestreamUrl,
    GeoPoint? location,
    DateTime? resolvedAt,
  }) {
    return EmergencyModel(
      emergencyId: emergencyId,
      userId: userId,
      status: status ?? this.status,
      triggeredBy: triggeredBy,
      location: location ?? this.location,
      audioUrl: audioUrl ?? this.audioUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      livestreamUrl: livestreamUrl ?? this.livestreamUrl,
      createdAt: createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
