class GuardianModel {
  GuardianModel({
    required this.guardianId,
    required this.userId,
    required this.name,
    required this.phone,
    required this.relationship,
    this.fcmToken,
  });

  final String guardianId;
  final String userId;
  final String name;
  final String phone;
  final String relationship;
  final String? fcmToken;

  factory GuardianModel.fromMap(Map<String, dynamic> data) {
    return GuardianModel(
      guardianId: data['guardian_id'] ?? data['guardianId'] ?? '',
      userId: data['user_id'] ?? data['userId'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      relationship: data['relationship'] ?? '',
      fcmToken: (data['fcm_token'] ?? data['fcmToken']) as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'guardian_id': guardianId,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'relationship': relationship,
      'fcm_token': fcmToken,
    };
  }
}
