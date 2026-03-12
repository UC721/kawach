class EmergencyProfileModel {
  final String bloodType;
  final List<String> allergies;
  final List<String> medications;
  final String? doctorPhone;
  final String? hospitalPreference;
  final String? specialInstructions;

  const EmergencyProfileModel({
    required this.bloodType,
    this.allergies = const [],
    this.medications = const [],
    this.doctorPhone,
    this.hospitalPreference,
    this.specialInstructions,
  });

  factory EmergencyProfileModel.fromMap(Map<String, dynamic> map) {
    return EmergencyProfileModel(
      bloodType: map['bloodType'] ?? 'Unknown',
      allergies: List<String>.from(map['allergies'] ?? []),
      medications: List<String>.from(map['medications'] ?? []),
      doctorPhone: map['doctorPhone'],
      hospitalPreference: map['hospitalPreference'],
      specialInstructions: map['specialInstructions'],
    );
  }

  Map<String, dynamic> toMap() => {
        'bloodType': bloodType,
        'allergies': allergies,
        'medications': medications,
        'doctorPhone': doctorPhone,
        'hospitalPreference': hospitalPreference,
        'specialInstructions': specialInstructions,
      };
}
