import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../models/device_token_model.dart';
import '../utils/constants.dart';

class DeviceTokenService extends ChangeNotifier {
  final SupabaseClient _db = Supabase.instance.client;

  /// Register or update a device push-notification token.
  Future<void> upsertToken({
    required String userId,
    required String token,
    required String platform,
  }) async {
    await _db.from(FSCollection.deviceTokens).upsert({
      'userId': userId,
      'token': token,
      'platform': platform,
      'updatedAt': DateTime.now().toIso8601String(),
    });
    notifyListeners();
  }

  /// Remove a device token (e.g. on logout).
  Future<void> removeToken({
    required String userId,
    required String token,
  }) async {
    await _db
        .from(FSCollection.deviceTokens)
        .delete()
        .eq('userId', userId)
        .eq('token', token);
    notifyListeners();
  }

  /// Get all tokens for a user.
  Future<List<DeviceTokenModel>> getTokens(String userId) async {
    final res = await _db
        .from(FSCollection.deviceTokens)
        .select()
        .eq('userId', userId);
    return (res as List)
        .map((d) => DeviceTokenModel.fromMap(d))
        .toList();
  }
}
