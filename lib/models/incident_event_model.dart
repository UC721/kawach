enum IncidentKind { emergency, resolved, evidence, acknowledgement, activity }

class IncidentEventModel {
  final String id;
  final IncidentKind kind;
  final DateTime timestamp;
  final String title;
  final String detail;
  final String? emergencyId;

  const IncidentEventModel({
    required this.id,
    required this.kind,
    required this.timestamp,
    required this.title,
    required this.detail,
    this.emergencyId,
  });
}
