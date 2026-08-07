enum GuardianRequestStatus { pending, accepted, declined }

class GuardianRequestModel {
  final String requestId;
  final String initiatorUserId;
  final String initiatorName;
  final String initiatorPhone;
  final String guardianUserId;
  final GuardianRequestStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const GuardianRequestModel({
    required this.requestId,
    required this.initiatorUserId,
    required this.initiatorName,
    required this.initiatorPhone,
    required this.guardianUserId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  factory GuardianRequestModel.fromMap(Map<String, dynamic> data) {
    return GuardianRequestModel(
      requestId: data['request_id'] ?? data['requestId'] ?? '',
      initiatorUserId:
          data['initiator_user_id'] ?? data['initiatorUserId'] ?? '',
      initiatorName: data['initiator_name'] ?? data['initiatorName'] ?? '',
      initiatorPhone: data['initiator_phone'] ?? data['initiatorPhone'] ?? '',
      guardianUserId: data['guardian_user_id'] ?? data['guardianUserId'] ?? '',
      status: GuardianRequestStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => GuardianRequestStatus.pending,
      ),
      createdAt: (data['created_at'] ?? data['createdAt']) != null
          ? DateTime.tryParse(data['created_at'] ?? data['createdAt']) ??
              DateTime.now()
          : DateTime.now(),
      respondedAt: (data['responded_at'] ?? data['respondedAt']) != null
          ? DateTime.tryParse(data['responded_at'] ?? data['respondedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'request_id': requestId,
        'initiator_user_id': initiatorUserId,
        'initiator_name': initiatorName,
        'initiator_phone': initiatorPhone,
        'guardian_user_id': guardianUserId,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
        'responded_at': respondedAt?.toIso8601String(),
      };
}
