enum SosAckStatus { checking, confirmedSafe, unableToHelp }

/// A guardian's response to a live SOS — the feedback that closes the loop so
/// the user and other guardians know "someone is on it / they are safe".
class SosAcknowledgementModel {
  final String ackId;
  final String emergencyId;
  final String emergencyUserId;
  final String guardianUserId;
  final String guardianName;
  final SosAckStatus status;
  final DateTime createdAt;

  const SosAcknowledgementModel({
    required this.ackId,
    required this.emergencyId,
    required this.emergencyUserId,
    required this.guardianUserId,
    required this.guardianName,
    required this.status,
    required this.createdAt,
  });

  factory SosAcknowledgementModel.fromMap(Map<String, dynamic> data) {
    return SosAcknowledgementModel(
      ackId: data['ack_id'] ?? data['ackId'] ?? '',
      emergencyId: data['emergency_id'] ?? data['emergencyId'] ?? '',
      emergencyUserId:
          data['emergency_user_id'] ?? data['emergencyUserId'] ?? '',
      guardianUserId: data['guardian_user_id'] ?? data['guardianUserId'] ?? '',
      guardianName: data['guardian_name'] ?? data['guardianName'] ?? '',
      status: SosAckStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => SosAckStatus.checking,
      ),
      createdAt: (data['created_at'] ?? data['createdAt']) != null
          ? DateTime.tryParse(data['created_at'] ?? data['createdAt']) ??
              DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'ack_id': ackId,
        'emergency_id': emergencyId,
        'emergency_user_id': emergencyUserId,
        'guardian_user_id': guardianUserId,
        'guardian_name': guardianName,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
      };
}
