import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/sos_alert_model.dart';

// ============================================================
// SosRemoteDatasource – Supabase network operations for SOS
// ============================================================

/// Handles all Supabase reads / writes for SOS alerts.
class SosRemoteDatasource {
  final SupabaseClient _client;

  SosRemoteDatasource(this._client);

  Future<SosAlertModel> createAlert(SosAlertModel model) async {
    try {
      final response = await _client
          .from(ApiEndpoints.emergencies)
          .insert(model.toMap())
          .select()
          .single();
      return SosAlertModel.fromMap(response);
    } catch (e) {
      throw ServerException(message: 'Failed to create SOS alert: $e');
    }
  }

  Future<SosAlertModel> updateAlert(
      String alertId, Map<String, dynamic> data) async {
    try {
      final response = await _client
          .from(ApiEndpoints.emergencies)
          .update(data)
          .eq('id', alertId)
          .select()
          .single();
      return SosAlertModel.fromMap(response);
    } catch (e) {
      throw ServerException(message: 'Failed to update SOS alert: $e');
    }
  }

  Future<SosAlertModel?> getActiveAlert(String userId) async {
    try {
      final response = await _client
          .from(ApiEndpoints.emergencies)
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response != null ? SosAlertModel.fromMap(response) : null;
    } catch (e) {
      throw ServerException(message: 'Failed to fetch active alert: $e');
    }
  }

  Stream<SosAlertModel?> watchAlert(String alertId) {
    return _client
        .from(ApiEndpoints.emergencies)
        .stream(primaryKey: ['id'])
        .eq('id', alertId)
        .map((rows) =>
            rows.isNotEmpty ? SosAlertModel.fromMap(rows.first) : null);
  }
}
