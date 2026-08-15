import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../models/audit_log_model.dart';
import '../utils/constants.dart';

class AuditLogService extends ChangeNotifier {
  final SupabaseClient _db = Supabase.instance.client;

  /// Write an entry to the audit log.
  Future<void> log({
    required String userId,
    required String action,
    String? tableName,
    String? recordId,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
  }) async {
    final entry = AuditLogModel(
      id: '',
      userId: userId,
      action: action,
      tableName: tableName,
      recordId: recordId,
      oldData: oldData,
      newData: newData,
      createdAt: DateTime.now(),
    );

    await _db
        .from(FSCollection.auditLog)
        .insert(entry.toMap());
  }

  /// Retrieve audit logs for a user, newest first.
  Future<List<AuditLogModel>> getLogs({
    required String userId,
    int limit = 50,
  }) async {
    final res = await _db
        .from(FSCollection.auditLog)
        .select()
        .eq('userId', userId)
        .order('createdAt', ascending: false)
        .limit(limit);
    return (res as List)
        .map((d) => AuditLogModel.fromMap(d))
        .toList();
  }
}
