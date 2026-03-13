
class GuardianModel {
  final String guardianId;
  final String userId;     // owner user
  final String name;
  final String phone;
  final String relationship;
  final String? fcmToken;

  GuardianModel({
    required this.guardianId,
    required this.userId,
    required this.name,
    required this.phone,
    required this.relationship,
    this.fcmToken,
  });

  factory GuardianModel.fromMap(Map<String, dynamic> data) {
    return GuardianModel(
      guardianId: data['guardianId'] ?? '',
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      relationship: data['relationship'] ?? '',
      fcmToken: data['fcmToken'],
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'phone': phone,
        'relationship': relationship,
        'fcmToken': fcmToken,
      };
}
