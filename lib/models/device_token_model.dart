class DeviceTokenModel {
  final String id;
  final String userId;
  final String token;
  final String platform;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeviceTokenModel({
    required this.id,
    required this.userId,
    required this.token,
    required this.platform,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DeviceTokenModel.fromMap(Map<String, dynamic> data) {
    return DeviceTokenModel(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      token: data['token'] ?? '',
      platform: data['platform'] ?? '',
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
      updatedAt: data['updatedAt'] != null
          ? DateTime.parse(data['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'token': token,
        'platform': platform,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };
}
