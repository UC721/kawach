
class GuardianModel {
  final String guardianId;
  final String userId;     // owner user
  final String name;
  final String phone;
  final String relationship;
  final bool verified;
  final String? fcmToken;

  GuardianModel({
    required this.guardianId,
    required this.userId,
    required this.name,
    required this.phone,
    required this.relationship,
    this.verified = false,
    this.fcmToken,
  });

  factory GuardianModel.fromMap(Map<String, dynamic> data) {
    return GuardianModel(
      guardianId: (data['id'] ?? data['guardianId'] ?? data['guardian_id'] ?? '').toString(),
      userId: (data['user_id'] ?? data['userId'] ?? '').toString(),
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      relationship: data['relationship'] ?? '',
      verified: data['verified'] ?? false,
      fcmToken: data['fcm_token'] ?? data['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'name': name,
        'phone': phone,
        'relationship': relationship,
        'verified': verified,
        'fcm_token': fcmToken,
      };
}
