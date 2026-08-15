class AuditLogModel {
  final String id;
  final String userId;
  final String action;
  final String? tableName;
  final String? recordId;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final String? ipAddress;
  final DateTime createdAt;

  AuditLogModel({
    required this.id,
    required this.userId,
    required this.action,
    this.tableName,
    this.recordId,
    this.oldData,
    this.newData,
    this.ipAddress,
    required this.createdAt,
  });

  factory AuditLogModel.fromMap(Map<String, dynamic> data) {
    return AuditLogModel(
      id: data['id'] ?? '',
      userId: data['userId'] ?? '',
      action: data['action'] ?? '',
      tableName: data['table_name'],
      recordId: data['record_id'],
      oldData: data['old_data'] != null
          ? Map<String, dynamic>.from(data['old_data'])
          : null,
      newData: data['new_data'] != null
          ? Map<String, dynamic>.from(data['new_data'])
          : null,
      ipAddress: data['ip_address'],
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'action': action,
        'table_name': tableName,
        'record_id': recordId,
        'old_data': oldData,
        'new_data': newData,
        'ip_address': ipAddress,
        'createdAt': createdAt.toIso8601String(),
      };
}
