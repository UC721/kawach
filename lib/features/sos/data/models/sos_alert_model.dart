import '../../domain/entities/sos_alert.dart';

// ============================================================
// SosAlertModel – Data-layer representation with serialisation
// ============================================================

/// Maps between the domain [SosAlert] entity and Supabase row maps.
class SosAlertModel extends SosAlert {
  const SosAlertModel({
    required super.id,
    required super.userId,
    required super.status,
    required super.triggeredBy,
    super.latitude,
    super.longitude,
    required super.createdAt,
    super.resolvedAt,
    super.audioEvidenceUrl,
    super.videoEvidenceUrl,
  });

  /// Deserialise from a Supabase row.
  factory SosAlertModel.fromMap(Map<String, dynamic> map) {
    return SosAlertModel(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      status: SosAlertStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SosAlertStatus.pending,
      ),
      triggeredBy: SosTriggerType.values.firstWhere(
        (e) => e.name == map['triggered_by'],
        orElse: () => SosTriggerType.button,
      ),
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      resolvedAt: map['resolved_at'] != null
          ? DateTime.tryParse(map['resolved_at'] as String)
          : null,
      audioEvidenceUrl: map['audio_evidence_url'] as String?,
      videoEvidenceUrl: map['video_evidence_url'] as String?,
    );
  }

  /// Create model from domain entity.
  factory SosAlertModel.fromEntity(SosAlert entity) {
    return SosAlertModel(
      id: entity.id,
      userId: entity.userId,
      status: entity.status,
      triggeredBy: entity.triggeredBy,
      latitude: entity.latitude,
      longitude: entity.longitude,
      createdAt: entity.createdAt,
      resolvedAt: entity.resolvedAt,
      audioEvidenceUrl: entity.audioEvidenceUrl,
      videoEvidenceUrl: entity.videoEvidenceUrl,
    );
  }

  /// Serialise to a Supabase-compatible map.
  Map<String, dynamic> toMap() {
    return {
      if (id.isNotEmpty) 'id': id,
      'user_id': userId,
      'status': status.name,
      'triggered_by': triggeredBy.name,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'audio_evidence_url': audioEvidenceUrl,
      'video_evidence_url': videoEvidenceUrl,
    };
  }
}
