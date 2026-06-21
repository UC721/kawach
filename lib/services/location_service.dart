import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/location_update_model.dart';
import '../utils/constants.dart';
import 'payload_cipher.dart';
import 'sos_queue_manager.dart';

class LocationService extends ChangeNotifier {
  LocationService({
    SosQueueManager? queueManager,
  }) : _queueManager = queueManager ?? SosQueueManager.instance;

  final SupabaseClient _db = Supabase.instance.client;
  final SosQueueManager _queueManager;

  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  bool _isTracking = false;

  Position? get currentPosition => _currentPosition;
  bool get isTracking => _isTracking;

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

  Future<void> startTracking(
    String userId,
    String emergencyId,
  ) async {
    await _ensurePermission();
    await stopTracking();
    _isTracking = true;

    _positionStream = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((position) async {
      _currentPosition = position;
      notifyListeners();
      await _uploadLocation(
        userId: userId,
        emergencyId: emergencyId,
        position: position,
      );
    });

    notifyListeners();
  }

  Future<void> stopTracking() async {
    await _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
    notifyListeners();
  }

  Stream<Position> get positionStream => Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

  Stream<Map<String, double>?> streamUserLocation(String userId) {
    return _db
        .from(FSCollection.users)
        .stream(primaryKey: ['user_id'])
        .eq('user_id', userId)
        .map((docs) {
      if (docs.isEmpty) {
        return null;
      }

      final doc = docs.first;
      if (doc['live_lat'] == null || doc['live_lng'] == null) {
        return null;
      }

      return {
        'lat': (doc['live_lat'] as num).toDouble(),
        'lng': (doc['live_lng'] as num).toDouble(),
      };
    });
  }

  double distanceBetween(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2);
  }

  Future<void> _uploadLocation({
    required String userId,
    required String emergencyId,
    required Position position,
  }) async {
    final update = LocationUpdateModel(
      emergencyId: emergencyId,
      userId: userId,
      lat: position.latitude,
      lng: position.longitude,
      speed: position.speed,
      heading: position.heading,
      accuracy: position.accuracy,
      recordedAt: DateTime.now(),
      encryptedPayload: PayloadCipher.encryptObject(
        {
          'lat': position.latitude,
          'lng': position.longitude,
          'speed': position.speed,
          'heading': position.heading,
          'accuracy': position.accuracy,
          'timestamp': DateTime.now().toIso8601String(),
        },
        scope: emergencyId,
      ),
    );

    try {
      await _db.from(FSCollection.locations).insert(update.toMap());
      await _db.from(FSCollection.emergencies).update({
        'lat': position.latitude,
        'lng': position.longitude,
        'location_updated_at': DateTime.now().toIso8601String(),
        'last_location_payload': update.encryptedPayload,
      }).eq('emergency_id', emergencyId);
      await _db.from(FSCollection.users).update({
        'live_lat': position.latitude,
        'live_lng': position.longitude,
        'live_location_updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);
    } catch (_) {
      await _queueManager.enqueueLocation(update);
    }
  }

  Future<void> _ensurePermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied. Please enable in settings.',
      );
    }
  }

  @override
  void dispose() {
    _positionStream?.cancel();
    super.dispose();
  }
}
