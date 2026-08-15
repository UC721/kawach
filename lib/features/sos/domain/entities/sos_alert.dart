// ============================================================
// SosAlert – Domain entity for SOS alerts
// ============================================================

/// Immutable domain entity representing an SOS alert.
///
/// This is the core business object – free of framework dependencies.
enum SosAlertStatus { pending, active, cancelled, resolved }

enum SosTriggerType { button, shake, voice, gesture, silent, automatic }

class SosAlert {
  final String id;
  final String userId;
  final SosAlertStatus status;
  final SosTriggerType triggeredBy;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  final DateTime? resolvedAt;
  final String? audioEvidenceUrl;
  final String? videoEvidenceUrl;

  const SosAlert({
    required this.id,
    required this.userId,
    required this.status,
    required this.triggeredBy,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.resolvedAt,
    this.audioEvidenceUrl,
    this.videoEvidenceUrl,
  });

  SosAlert copyWith({
    String? id,
    String? userId,
    SosAlertStatus? status,
    SosTriggerType? triggeredBy,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? resolvedAt,
    String? audioEvidenceUrl,
    String? videoEvidenceUrl,
  }) {
    return SosAlert(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      triggeredBy: triggeredBy ?? this.triggeredBy,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      audioEvidenceUrl: audioEvidenceUrl ?? this.audioEvidenceUrl,
      videoEvidenceUrl: videoEvidenceUrl ?? this.videoEvidenceUrl,
    );
  }
}
