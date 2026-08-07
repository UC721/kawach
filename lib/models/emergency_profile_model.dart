class EmergencyContact {
  final String name;
  final String phone;
  final String relationship;

  const EmergencyContact({
    required this.name,
    required this.phone,
    this.relationship = '',
  });

  factory EmergencyContact.fromMap(Map<String, dynamic> map) {
    return EmergencyContact(
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      relationship: map['relationship'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'phone': phone,
        'relationship': relationship,
      };
}

class EmergencyProfileModel {
  final String bloodType;
  final List<String> allergies;
  final List<String> medications;
  final List<String> conditions;
  final String? doctorPhone;
  final String? hospitalPreference;
  final String? specialInstructions;
  final String? insuranceProvider;
  final String? insurancePolicyNo;
  final String? legalHolder;
  final String? legalHolderPhone;
  final bool organDonor;
  final List<EmergencyContact> emergencyContacts;

  const EmergencyProfileModel({
    this.bloodType = 'Unknown',
    this.allergies = const [],
    this.medications = const [],
    this.conditions = const [],
    this.doctorPhone,
    this.hospitalPreference,
    this.specialInstructions,
    this.insuranceProvider,
    this.insurancePolicyNo,
    this.legalHolder,
    this.legalHolderPhone,
    this.organDonor = false,
    this.emergencyContacts = const [],
  });

  factory EmergencyProfileModel.fromMap(Map<String, dynamic> map) {
    final rawContacts = map['emergencyContacts'] ?? map['emergency_contacts'];
    return EmergencyProfileModel(
      bloodType: map['bloodType'] ?? map['blood_type'] ?? 'Unknown',
      allergies: List<String>.from(map['allergies'] ?? []),
      medications: List<String>.from(map['medications'] ?? []),
      conditions: List<String>.from(map['conditions'] ?? []),
      doctorPhone: map['doctorPhone'] ?? map['doctor_phone'],
      hospitalPreference:
          map['hospitalPreference'] ?? map['hospital_preference'],
      specialInstructions:
          map['specialInstructions'] ?? map['special_instructions'],
      insuranceProvider: map['insuranceProvider'] ?? map['insurance_provider'],
      insurancePolicyNo: map['insurancePolicyNo'] ?? map['insurance_policy_no'],
      legalHolder: map['legalHolder'] ?? map['legal_holder'],
      legalHolderPhone: map['legalHolderPhone'] ?? map['legal_holder_phone'],
      organDonor: map['organDonor'] ?? false,
      emergencyContacts: rawContacts == null
          ? const []
          : (rawContacts as List)
              .map((e) => EmergencyContact.fromMap(e as Map<String, dynamic>))
              .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'bloodType': bloodType,
        'allergies': allergies,
        'medications': medications,
        'conditions': conditions,
        'doctorPhone': doctorPhone,
        'hospitalPreference': hospitalPreference,
        'specialInstructions': specialInstructions,
        'insuranceProvider': insuranceProvider,
        'insurancePolicyNo': insurancePolicyNo,
        'legalHolder': legalHolder,
        'legalHolderPhone': legalHolderPhone,
        'organDonor': organDonor,
        'emergencyContacts': emergencyContacts.map((e) => e.toMap()).toList(),
      };

  EmergencyProfileModel copyWith({
    String? bloodType,
    List<String>? allergies,
    List<String>? medications,
    List<String>? conditions,
    String? doctorPhone,
    String? hospitalPreference,
    String? specialInstructions,
    String? insuranceProvider,
    String? insurancePolicyNo,
    String? legalHolder,
    String? legalHolderPhone,
    bool? organDonor,
    List<EmergencyContact>? emergencyContacts,
  }) {
    return EmergencyProfileModel(
      bloodType: bloodType ?? this.bloodType,
      allergies: allergies ?? this.allergies,
      medications: medications ?? this.medications,
      conditions: conditions ?? this.conditions,
      doctorPhone: doctorPhone ?? this.doctorPhone,
      hospitalPreference: hospitalPreference ?? this.hospitalPreference,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      insuranceProvider: insuranceProvider ?? this.insuranceProvider,
      insurancePolicyNo: insurancePolicyNo ?? this.insurancePolicyNo,
      legalHolder: legalHolder ?? this.legalHolder,
      legalHolderPhone: legalHolderPhone ?? this.legalHolderPhone,
      organDonor: organDonor ?? this.organDonor,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
    );
  }

  /// True when no meaningful data has been entered yet.
  bool get isEmpty =>
      bloodType == 'Unknown' &&
      allergies.isEmpty &&
      medications.isEmpty &&
      conditions.isEmpty &&
      doctorPhone == null &&
      hospitalPreference == null &&
      insuranceProvider == null &&
      legalHolder == null &&
      emergencyContacts.isEmpty;
}
