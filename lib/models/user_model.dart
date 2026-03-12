import 'package:cloud_firestore/cloud_firestore.dart';
import 'emergency_profile_model.dart';

class UserModel {
  final String userId;
  final String name;
  final String phone;
  final String? email;
  final List<String> guardianIds;
  final EmergencyProfileModel? emergencyProfile;
  final DateTime createdAt;

  UserModel({
    required this.userId,
    required this.name,
    required this.phone,
    this.email,
    this.guardianIds = const [],
    this.emergencyProfile,
    required this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      userId: doc.id,
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      guardianIds: List<String>.from(data['guardians'] ?? []),
      emergencyProfile: data['emergencyProfile'] != null
          ? EmergencyProfileModel.fromMap(
              data['emergencyProfile'] as Map<String, dynamic>)
          : null,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'email': email,
        'guardians': guardianIds,
        'emergencyProfile': emergencyProfile?.toMap(),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  UserModel copyWith({
    String? name,
    String? phone,
    String? email,
    List<String>? guardianIds,
    EmergencyProfileModel? emergencyProfile,
  }) {
    return UserModel(
      userId: userId,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      guardianIds: guardianIds ?? this.guardianIds,
      emergencyProfile: emergencyProfile ?? this.emergencyProfile,
      createdAt: createdAt,
    );
  }
}
