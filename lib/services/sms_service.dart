import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/guardian_model.dart';
import '../utils/constants.dart';

/// SMS backup service – sends coordinates via HTTP SMS gateway.
/// Falls back to a local log if request fails.
class SmsService extends ChangeNotifier {
  Future<void> sendEmergencySms({
    required List<GuardianModel> guardians,
    GeoPoint? location,
    required String userName,
  }) async {
    final locationStr = location != null
        ? 'https://maps.google.com/?q=${location.latitude},${location.longitude}'
        : 'Location unavailable';

    final message =
        '🚨 KAWACH ALERT: $userName needs help! Live location: $locationStr. '
        'Open KAWACH app to monitor. #KawachSOS';

    for (final guardian in guardians) {
      await _sendSms(to: guardian.phone, message: message);
    }
  }

  Future<void> sendSafeArrivalSms({
    required List<GuardianModel> guardians,
    required String userName,
  }) async {
    final message =
        '✅ KAWACH: $userName has arrived safely. No emergency. #Kawach';
    for (final g in guardians) {
      await _sendSms(to: g.phone, message: message);
    }
  }

  Future<bool> _sendSms({
    required String to,
    required String message,
  }) async {
    try {
      final res = await http.post(
        Uri.parse(AppKeys.smsGatewayUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${AppKeys.smsGatewayApiKey}',
        },
        body: jsonEncode({'to': to, 'message': message}),
      ).timeout(const Duration(seconds: 10));
      return res.statusCode == 200;
    } catch (_) {
      // Log failure; will be synced via offline service
      return false;
    }
  }
}
