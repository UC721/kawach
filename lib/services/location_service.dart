import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../utils/constants.dart';

class LocationService extends ChangeNotifier {
  SupabaseClient get _db => Supabase.instance.client;

  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  Timer? _uploadTimer;

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
    // Update emergency document
    await _db.from(FSCollection.emergencies).update({
      'lat': pos.latitude,
      'lng': pos.longitude,
      'locationUpdatedAt': DateTime.now().toIso8601String(),
    }).eq('emergencyId', emergencyId);

    // Update user's live location
    await _db.from(FSCollection.users).update({
      'liveLat': pos.latitude,
      'liveLng': pos.longitude,
      'liveLocationUpdatedAt': DateTime.now().toIso8601String(),
    }).eq('userId', userId);
  }

  // ── Stop tracking ────────────────────────────────────────────
  Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
    _uploadTimer?.cancel();
    _isTracking = false;
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
  Stream<Map<String, double>?> streamUserLocation(String userId) {
    return _db
        .from(FSCollection.users)
        .stream(primaryKey: ['userId'])
        .eq('userId', userId)
        .map((docs) {
          if (docs.isEmpty) return null;
          final doc = docs.first;
          if (doc['liveLat'] == null || doc['liveLng'] == null) return null;
          return {
            'lat': (doc['liveLat'] as num).toDouble(),
            'lng': (doc['liveLng'] as num).toDouble(),
          };
        });
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
