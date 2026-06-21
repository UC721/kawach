import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/guardian_network_model.dart';
import '../models/nearby_alert_model.dart';
import '../utils/constants.dart';

class GuardianNetworkService extends ChangeNotifier {
  final SupabaseClient _db = Supabase.instance.client;

  List<GuardianNetworkModel> _nearbyVolunteers = [];
  List<GuardianNetworkModel> get nearbyVolunteers => _nearbyVolunteers;

  bool _isRegistered = false;
  bool get isRegistered => _isRegistered;

  Future<void> registerAsVolunteer({
    required String name,
    required String phone,
    required double lat,
    required double lng,
  }) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      return;
    }

    await _db.from(FSCollection.guardianNetwork).upsert({
      'volunteer_id': uid,
      'user_id': uid,
      'name': name,
      'lat': lat,
      'lng': lng,
      'verified': false,
      'availability': true,
      'phone': phone,
      'last_seen': DateTime.now().toIso8601String(),
    });

    _isRegistered = true;
    notifyListeners();
  }

  Future<void> updateVolunteerStatus({
    required bool available,
    double? lat,
    double? lng,
  }) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      return;
    }

    final update = <String, dynamic>{
      'availability': available,
      'last_seen': DateTime.now().toIso8601String(),
    };
    if (lat != null && lng != null) {
      update['lat'] = lat;
      update['lng'] = lng;
    }

    await _db
        .from(FSCollection.guardianNetwork)
        .update(update)
        .eq('volunteer_id', uid);
    notifyListeners();
  }

  Future<List<GuardianNetworkModel>> findNearbyVolunteers({
    required double lat,
    required double lng,
    double radiusMeters = AppThresholds.volunteerSearchRadius,
  }) async {
    final response = await _db
        .from(FSCollection.guardianNetwork)
        .select()
        .eq('availability', true)
        .eq('verified', true);

    _nearbyVolunteers = (response as List)
        .map((item) => GuardianNetworkModel.fromMap(item as Map<String, dynamic>))
        .where((volunteer) {
      if (volunteer.lat == null || volunteer.lng == null) {
        return false;
      }
      return Geolocator.distanceBetween(
            lat,
            lng,
            volunteer.lat!,
            volunteer.lng!,
          ) <=
          radiusMeters;
    }).toList();

    notifyListeners();
    return _nearbyVolunteers;
  }

  Future<void> alertNearbyVolunteers({
    required String emergencyId,
    required String userId,
    required String userName,
    required double lat,
    required double lng,
  }) async {
    final volunteers = await findNearbyVolunteers(lat: lat, lng: lng);
    for (final volunteer in volunteers) {
      await _db.from(FSCollection.volunteerAlerts).insert({
        'volunteer_id': volunteer.volunteerId,
        'emergency_id': emergencyId,
        'user_id': userId,
        'user_name': userName,
        'lat': lat,
        'lng': lng,
        'sent_at': DateTime.now().toIso8601String(),
        'status': 'pending',
      });
    }
  }

  Stream<List<GuardianNetworkModel>> streamVolunteers() {
    return _db
        .from(FSCollection.guardianNetwork)
        .stream(primaryKey: ['volunteer_id'])
        .eq('verified', true)
        .map((docs) => docs
            .map((doc) => GuardianNetworkModel.fromMap(doc))
            .toList());
  }

  Stream<List<NearbyAlertModel>> streamIncomingAlerts() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      return Stream.value(const []);
    }

    return _db
        .from(FSCollection.volunteerAlerts)
        .stream(primaryKey: ['alert_id'])
        .eq('volunteer_id', uid)
        .map((docs) => docs
            .map((doc) => NearbyAlertModel.fromMap(doc))
            .where((alert) => alert.isActive)
            .toList()
          ..sort((left, right) => right.createdAt.compareTo(left.createdAt)));
  }
}
