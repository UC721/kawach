import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory GuardianModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GuardianModel(
      guardianId: doc.id,
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
