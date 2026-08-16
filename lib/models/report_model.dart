
class ReportModel {
  final String reportId;
  final String userId;
  final String description;
  final String? imageUrl;
  final double? lat;
  final double? lng;
  final String? address;
  final DateTime createdAt;
  final int upvotes;

  ReportModel({
    required this.reportId,
    required this.userId,
    required this.description,
    this.imageUrl,
    this.lat,
    this.lng,
    this.address,
    required this.createdAt,
    this.upvotes = 0,
  });

  factory ReportModel.fromMap(Map<String, dynamic> data) {
    return ReportModel(
      reportId: (data['id'] ?? data['reportId'] ?? data['report_id'] ?? '').toString(),
      userId: (data['userId'] ?? data['user_id'] ?? '').toString(),
      description: data['description'] ?? '',
      imageUrl: data['image_url'] ?? data['imageUrl'],
      lat: (data['latitude'] ?? data['lat'])?.toDouble(),
      lng: (data['longitude'] ?? data['lng'])?.toDouble(),
      address: data['address'] ?? data['location'],
      createdAt: (data['created_at'] ?? data['createdAt']) != null 
          ? DateTime.parse(data['created_at'] ?? data['createdAt']) 
          : DateTime.now(),
      upvotes: data['upvotes'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'description': description,
        'image_url': imageUrl,
        'lat': lat,
        'lng': lng,
        'address': address,
        'created_at': createdAt.toIso8601String(),
      };
}
