import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/sos_alert_model.dart';

// ============================================================
// SosLocalDatasource – Offline-first local cache for SOS alerts
// ============================================================

/// Stores SOS alerts locally when the network is unreachable.
class SosLocalDatasource {
  static const _pendingAlertsKey = 'pending_sos_alerts';

  Future<void> cacheAlert(SosAlertModel model) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getStringList(_pendingAlertsKey) ?? [];
      existing.add(jsonEncode(model.toMap()));
      await prefs.setStringList(_pendingAlertsKey, existing);
    } catch (e) {
      throw CacheException(message: 'Failed to cache SOS alert: $e');
    }
  }

  Future<List<SosAlertModel>> getPendingAlerts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList(_pendingAlertsKey) ?? [];
      return stored
          .map((json) =>
              SosAlertModel.fromMap(jsonDecode(json) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw CacheException(message: 'Failed to read cached alerts: $e');
    }
  }

  Future<void> clearPendingAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingAlertsKey);
  }
}
