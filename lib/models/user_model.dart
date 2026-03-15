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

  factory UserModel.fromMap(Map<String, dynamic> data) {
    return UserModel(
      userId: data['userId'] ?? data['user_id'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      email: data['email'],
      guardianIds: List<String>.from(data['guardians'] ?? []),
      emergencyProfile: (data['emergencyProfile'] ?? data['emergency_profile']) != null
          ? EmergencyProfileModel.fromMap(
              (data['emergencyProfile'] ?? data['emergency_profile']) as Map<String, dynamic>)
          : null,
      createdAt: (data['createdAt'] ?? data['created_at']) != null
          ? DateTime.parse(data['createdAt'] ?? data['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'email': email,
        'guardians': guardianIds,
        'emergencyProfile': emergencyProfile?.toMap(),
        'createdAt': createdAt.toIso8601String(),
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
