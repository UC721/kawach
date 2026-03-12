import 'package:cloud_firestore/cloud_firestore.dart';

class GuardianNetworkModel {
  final String volunteerId;
  final String userId; // volunteer's user account
  final String name;
  final GeoPoint? location;
  final bool verified;
  final bool availability;
  final String? phone;
  final DateTime? lastSeen;

  GuardianNetworkModel({
    required this.volunteerId,
    required this.userId,
    required this.name,
    this.location,
    required this.verified,
    required this.availability,
    this.phone,
    this.lastSeen,
  });

  factory GuardianNetworkModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GuardianNetworkModel(
      volunteerId: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      location: data['location'] as GeoPoint?,
      verified: data['verified'] ?? false,
      availability: data['availability'] ?? false,
      phone: data['phone'],
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'name': name,
        'location': location,
        'verified': verified,
        'availability': availability,
        'phone': phone,
        'lastSeen':
            lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
      };
}
