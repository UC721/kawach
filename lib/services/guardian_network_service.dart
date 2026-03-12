import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/guardian_network_model.dart';
import '../utils/constants.dart';

class GuardianNetworkService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final volunteer = GuardianNetworkModel(
      volunteerId: uid,
      userId: uid,
      name: name,
      location: GeoPoint(lat, lng),
      verified: false, // Admin must verify
      availability: true,
      phone: phone,
      lastSeen: DateTime.now(),
    );

    await _db
        .collection(FSCollection.guardianNetwork)
        .doc(uid)
        .set(volunteer.toMap());

    _isRegistered = true;
    notifyListeners();
  }

  // ── Update volunteer location and availability ───────────────
  Future<void> updateVolunteerStatus({
    required bool available,
    double? lat,
    double? lng,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final update = <String, dynamic>{
      'availability': available,
      'lastSeen': FieldValue.serverTimestamp(),
    };
    if (lat != null && lng != null) {
      update['location'] = GeoPoint(lat, lng);
    }

    await _db
        .collection(FSCollection.guardianNetwork)
        .doc(uid)
        .update(update);
    notifyListeners();
  }

  // ── Find nearby available verified volunteers ─────────────────
  Future<List<GuardianNetworkModel>> findNearbyVolunteers({
    required double lat,
    required double lng,
    double radiusMeters = AppThresholds.volunteerSearchRadius,
  }) async {
    final snap = await _db
        .collection(FSCollection.guardianNetwork)
        .where('availability', isEqualTo: true)
        .where('verified', isEqualTo: true)
        .get();

    _nearbyVolunteers = snap.docs
        .map((d) => GuardianNetworkModel.fromFirestore(d))
        .where((v) {
          if (v.location == null) return false;
          return Geolocator.distanceBetween(
                  lat, lng, v.location!.latitude, v.location!.longitude) <=
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
      await _db.collection('volunteerAlerts').add({
        'volunteerId': vol.volunteerId,
        'emergencyId': emergencyId,
        'userId': userId,
        'location': GeoPoint(lat, lng),
        'sentAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });
    }
  }

  // ── Stream for volunteer list ─────────────────────────────────
  Stream<List<GuardianNetworkModel>> streamVolunteers() {
    return _db
        .collection(FSCollection.guardianNetwork)
        .where('verified', isEqualTo: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => GuardianNetworkModel.fromFirestore(d)).toList());
  }
}
