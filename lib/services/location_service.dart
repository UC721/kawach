import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../utils/constants.dart';

class LocationService extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  Timer? _uploadTimer;
  String? _trackedUserId;
  bool _isTracking = false;

  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;

  // ── One-shot location fetch ──────────────────────────────────
  Future<Position> getCurrentPosition() async {
    await _ensurePermission();
    _currentPosition = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    );
    notifyListeners();
    return _currentPosition!;
  }

  // ── Start live tracking ──────────────────────────────────────
  Future<void> startTracking(String userId, String emergencyId) async {
    await _ensurePermission();
    _trackedUserId = userId;
    _isTracking = true;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((pos) async {
      _currentPosition = pos;
      notifyListeners();
      // Upload to Firestore every 5 seconds
      await _uploadLocation(userId, emergencyId, pos);
    });

    notifyListeners();
  }

  Future<void> _uploadLocation(
      String userId, String emergencyId, Position pos) async {
    final geoPoint = GeoPoint(pos.latitude, pos.longitude);

    // Update emergency document
    await _db.collection(FSCollection.emergencies).doc(emergencyId).update({
      'location': geoPoint,
      'locationUpdatedAt': FieldValue.serverTimestamp(),
    });

    // Update user's live location
    await _db.collection(FSCollection.users).doc(userId).update({
      'liveLocation': geoPoint,
      'liveLocationUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Stop tracking ────────────────────────────────────────────
  Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
    _uploadTimer?.cancel();
    _isTracking = false;
    _trackedUserId = null;
    notifyListeners();
  }

  // ── Stream for UI ────────────────────────────────────────────
  Stream<Position> get positionStream => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

  // ── Guard live location in Firestore ─────────────────────────
  Stream<GeoPoint?> streamUserLocation(String userId) {
    return _db
        .collection(FSCollection.users)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data()?['liveLocation'] as GeoPoint?);
  }

  // ── Permission ───────────────────────────────────────────────
  Future<void> _ensurePermission() async {
    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      throw Exception(
          'Location permission permanently denied. Please enable in settings.');
    }
  }

  double distanceBetween(
      double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    _uploadTimer?.cancel();
    super.dispose();
  }
}
