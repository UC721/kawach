import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../models/volunteer_response_model.dart';
import '../utils/constants.dart';

class VolunteerResponseService extends ChangeNotifier {
  final SupabaseClient _db = Supabase.instance.client;

  /// Record a volunteer's response to an emergency alert.
  Future<void> respond({
    required String volunteerId,
    required String emergencyId,
    required String userId,
    required String status,
    double? lat,
    double? lng,
  }) async {
    final response = VolunteerResponseModel(
      id: '',
      volunteerId: volunteerId,
      emergencyId: emergencyId,
      userId: userId,
      status: status,
      respondedAt: DateTime.now(),
      lat: lat,
      lng: lng,
      createdAt: DateTime.now(),
    );

    await _db
        .from(FSCollection.volunteerResponses)
        .insert(response.toMap());
  }

  /// Update the status of an existing volunteer response.
  Future<void> updateStatus({
    required String responseId,
    required String status,
    double? lat,
    double? lng,
  }) async {
    final update = <String, dynamic>{
      'status': status,
    };
    if (status == 'arrived') {
      update['arrivedAt'] = DateTime.now().toIso8601String();
    }
    if (lat != null && lng != null) {
      update['lat'] = lat;
      update['lng'] = lng;
    }

    await _db
        .from(FSCollection.volunteerResponses)
        .update(update)
        .eq('id', responseId);
    notifyListeners();
  }

  /// Fetch all responses for a given emergency.
  Future<List<VolunteerResponseModel>> getResponsesForEmergency(
      String emergencyId) async {
    final res = await _db
        .from(FSCollection.volunteerResponses)
        .select()
        .eq('emergencyId', emergencyId)
        .order('createdAt', ascending: true);
    return (res as List)
        .map((d) => VolunteerResponseModel.fromMap(d))
        .toList();
  }

  /// Stream responses for an emergency in real time.
  Stream<List<VolunteerResponseModel>> streamResponses(
      String emergencyId) {
    return _db
        .from(FSCollection.volunteerResponses)
        .stream(primaryKey: ['id'])
        .eq('emergencyId', emergencyId)
        .map((docs) => docs
            .map((d) => VolunteerResponseModel.fromMap(d))
            .toList());
  }
}
