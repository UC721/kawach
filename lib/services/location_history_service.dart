import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../models/location_history_model.dart';
import '../utils/constants.dart';

class LocationHistoryService extends ChangeNotifier {
  final SupabaseClient _db = Supabase.instance.client;

  /// Record a location snapshot into the partitioned history table.
  Future<void> record({
    required String userId,
    required double lat,
    required double lng,
    double? accuracy,
  }) async {
    final entry = LocationHistoryModel(
      id: '',
      userId: userId,
      lat: lat,
      lng: lng,
      accuracy: accuracy,
      recordedAt: DateTime.now(),
    );

    await _db
        .from(FSCollection.locationHistory)
        .insert(entry.toMap());
  }

  /// Retrieve location history for a user within a time range.
  Future<List<LocationHistoryModel>> getHistory({
    required String userId,
    required DateTime from,
    required DateTime to,
  }) async {
    final res = await _db
        .from(FSCollection.locationHistory)
        .select()
        .eq('userId', userId)
        .gte('recordedAt', from.toIso8601String())
        .lte('recordedAt', to.toIso8601String())
        .order('recordedAt', ascending: true);
    return (res as List)
        .map((d) => LocationHistoryModel.fromMap(d))
        .toList();
  }
}
