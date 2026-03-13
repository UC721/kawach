import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/guardian_network_model.dart';
import '../utils/constants.dart';

class GuardianNetworkService extends ChangeNotifier {
  final SupabaseClient _db = Supabase.instance.client;

  List<GuardianNetworkModel> _nearbyVolunteers = [];
  List<GuardianNetworkModel> get nearbyVolunteers => _nearbyVolunteers;

  bool _isRegistered = false;
  bool get isRegistered => _isRegistered;

  // ── Register as a volunteer ──────────────────────────────────
  Future<void> registerAsVolunteer({
    required String name,
    required String phone,
    required double lat,
    required double lng,
  }) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    final volunteer = GuardianNetworkModel(
      volunteerId: uid,
      userId: uid,
      name: name,
      lat: lat,
      lng: lng,
      verified: false, // Admin must verify
      availability: true,
      phone: phone,
      lastSeen: DateTime.now(),
    );

    await _db
        .from(FSCollection.guardianNetwork)
        .upsert(volunteer.toMap());

    _isRegistered = true;
    notifyListeners();
  }

  // ── Update volunteer location and availability ───────────────
  Future<void> updateVolunteerStatus({
    required bool available,
    double? lat,
    double? lng,
  }) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    final update = <String, dynamic>{
      'availability': available,
      'lastSeen': DateTime.now().toIso8601String(),
    };
    if (lat != null && lng != null) {
      update['lat'] = lat;
      update['lng'] = lng;
    }

    await _db
        .from(FSCollection.guardianNetwork)
        .update(update)
        .eq('volunteerId', uid);
    notifyListeners();
  }

  // ── Find nearby available verified volunteers ─────────────────
  Future<List<GuardianNetworkModel>> findNearbyVolunteers({
    required double lat,
    required double lng,
    double radiusMeters = AppThresholds.volunteerSearchRadius,
  }) async {
    // In a real scenario, this would ideally be done via a PostGIS RPC function:
    // final res = await _db.rpc('find_nearby_volunteers', params: {'user_lat': lat, 'user_lng': lng, 'radius': radiusMeters});
    // For now, we fetch all available and verified and filter in Dart (same as Firestore before).
    final res = await _db
        .from(FSCollection.guardianNetwork)
        .select()
        .eq('availability', true)
        .eq('verified', true);

    _nearbyVolunteers = (res as List)
        .map((d) => GuardianNetworkModel.fromMap(d))
        .where((v) {
          if (v.lat == null || v.lng == null) return false;
          return Geolocator.distanceBetween(
                  lat, lng, v.lat!, v.lng!) <=
              radiusMeters;
        })
        .toList();

    notifyListeners();
    return _nearbyVolunteers;
  }

  // ── Alert nearby volunteers of emergency ─────────────────────
  Future<void> alertNearbyVolunteers({
    required String emergencyId,
    required String userId,
    required double lat,
    required double lng,
  }) async {
    final volunteers = await findNearbyVolunteers(lat: lat, lng: lng);

    // Store alert references so volunteers can pull details
    for (final vol in volunteers) {
      await _db.from(FSCollection.volunteerAlerts).insert({
        'volunteerId': vol.volunteerId,
        'emergencyId': emergencyId,
        'userId': userId,
        'lat': lat,
        'lng': lng,
        'sentAt': DateTime.now().toIso8601String(),
        'status': 'pending',
      });
    }
  }

  // ── Stream for volunteer list ─────────────────────────────────
  Stream<List<GuardianNetworkModel>> streamVolunteers() {
    return _db
        .from(FSCollection.guardianNetwork)
        .stream(primaryKey: ['volunteerId'])
        .eq('verified', true)
        .map((docs) =>
            docs.map((d) => GuardianNetworkModel.fromMap(d)).toList());
  }
}
