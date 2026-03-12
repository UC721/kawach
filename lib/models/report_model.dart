import 'package:cloud_firestore/cloud_firestore.dart';

class ReportModel {
  final String reportId;
  final String userId;
  final String description;
  final String? imageUrl;
  final GeoPoint? location;
  final String? address;
  final DateTime createdAt;
  final int upvotes;

  ReportModel({
    required this.reportId,
    required this.userId,
    required this.description,
    this.imageUrl,
    this.location,
    this.address,
    required this.createdAt,
    this.upvotes = 0,
  });

  factory ReportModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportModel(
      reportId: doc.id,
      userId: data['userId'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      location: data['location'] as GeoPoint?,
      address: data['address'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      upvotes: data['upvotes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'description': description,
        'imageUrl': imageUrl,
        'location': location,
        'address': address,
        'createdAt': Timestamp.fromDate(createdAt),
        'upvotes': upvotes,
      };
}
