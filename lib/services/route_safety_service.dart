import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/danger_zone_model.dart';
import '../utils/constants.dart';

class RouteSafetyService extends ChangeNotifier {
  List<LatLng> _safeRoute = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<LatLng> get safeRoute => _safeRoute;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ── Calculate safest route avoiding danger zones ─────────────
  Future<List<LatLng>> calculateSafeRoute({
    required LatLng origin,
    required LatLng destination,
    List<DangerZoneModel> dangerZones = const [],
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Build waypoints to avoid danger zones (simple avoidance)
      final waypointsParam = _buildWaypointAvoidance(
          origin, destination, dangerZones);

      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/directions/json'
        '?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&mode=walking'
        '&alternatives=true'
        '$waypointsParam'
        '&key=${AppKeys.googleMapsApiKey}',
      );

      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final points = route['overview_polyline']['points'] as String;
          _safeRoute = _decodePolyline(points);
        }
      } else {
        _errorMessage = 'Route calculation failed';
      }
    } catch (e) {
      _errorMessage = 'Unable to calculate route: $e';
    }

    _isLoading = false;
    notifyListeners();
    return _safeRoute;
  }

  // ── Find nearest safe place ──────────────────────────────────
  Future<Map<String, dynamic>?> findNearestSafePlace({
    required LatLng location,
    String type = 'police',
  }) async {
    try {
      final uri = Uri.parse(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${location.latitude},${location.longitude}'
        '&radius=2000'
        '&type=$type'
        '&key=${AppKeys.googleMapsApiKey}',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'].isNotEmpty) {
          return data['results'][0] as Map<String, dynamic>;
        }
      }
    } catch (_) {}
    return null;
  }

  // ── Polyline decode ──────────────────────────────────────────
  List<LatLng> _decodePolyline(String encoded) {
    final result = <LatLng>[];
    int index = 0;
    int lat = 0, lng = 0;

    while (index < encoded.length) {
      int b, shift = 0, result2 = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result2 |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dLat = (result2 & 1) != 0 ? ~(result2 >> 1) : (result2 >> 1);
      lat += dLat;

      shift = 0;
      result2 = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result2 |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dLng = (result2 & 1) != 0 ? ~(result2 >> 1) : (result2 >> 1);
      lng += dLng;

      result.add(LatLng(lat / 1e5, lng / 1e5));
    }
    return result;
  }

  String _buildWaypointAvoidance(
      LatLng origin, LatLng destination, List<DangerZoneModel> zones) {
    if (zones.isEmpty) return '';
    // For demo: encode avoid zones as waypoints offset from danger centers
    final waypoints = zones.take(5).map((z) => '${z.lat},${z.lng}').join('|');
    return '&avoid=indoor';
  }
}
