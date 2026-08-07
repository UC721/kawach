import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/danger_zone_model.dart';
import '../utils/constants.dart';

/// Safe-route engine backed by free, keyless providers (no Google required):
/// - Directions: OpenRouteService (ORS) public API
/// - Safe places: Nominatim (OpenStreetMap) geocoding
/// Danger avoidance scoring keeps routes away from reported risk zones.
class RouteSafetyService extends ChangeNotifier {
  List<LatLng> _safeRoute = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<LatLng> get safeRoute => _safeRoute;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<List<LatLng>> calculateSafeRoute({
    required LatLng origin,
    required LatLng destination,
    List<DangerZoneModel> dangerZones = const [],
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _safeRoute = await _fetchOsrmRoute(origin, destination, dangerZones);
    } catch (e) {
      _errorMessage = 'Unable to calculate route: ${e.toString()}';
      _safeRoute = const [];
    }

    _isLoading = false;
    notifyListeners();
    return _safeRoute;
  }

  /// OSRM public router — real street walking/cycling geometry, no key needed.
  Future<List<LatLng>> _fetchOsrmRoute(
    LatLng origin,
    LatLng destination,
    List<DangerZoneModel> dangerZones,
  ) async {
    final uri = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${origin.longitude},${origin.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=polyline&alternatives=true',
    );
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      return _fallbackStraightLine(origin, destination);
    }

    final data = jsonDecode(response.body);
    final routes = data['routes'] as List<dynamic>? ?? const [];

    if (routes.isEmpty) {
      return _fallbackStraightLine(origin, destination);
    }

    var safest = routes.first;
    var minScore = double.infinity;
    for (final route in routes) {
      final points = _decodePolyline(route['geometry'] as String? ?? '');
      final score = _calculateDangerScore(points, dangerZones);
      if (score < minScore) {
        minScore = score;
        safest = route;
      }
    }

    final result = _decodePolyline(safest['geometry'] as String? ?? '');
    return result.isEmpty ? _fallbackStraightLine(origin, destination) : result;
  }

  /// If routing is unavailable, at least draw a straight line so the user is
  /// never staring at an empty map.
  List<LatLng> _fallbackStraightLine(LatLng origin, LatLng destination) {
    return [
      origin,
      LatLng(
        (origin.latitude + destination.latitude) / 2,
        (origin.longitude + destination.longitude) / 2,
      ),
      destination,
    ];
  }

  /// Nominatim (OpenStreetMap) search — returns the nearest match as a LatLng,
  /// or null if nothing was found.
  Future<LatLng?> findNearestSafePlace({
    required LatLng location,
    String type = 'police',
  }) async {
    final query =
        {'police': 'police station', 'hospital': 'hospital'}[type] ?? type;
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?format=json&limit=5'
        '&q=${Uri.encodeQueryComponent(query)}'
        '&lat=${location.latitude}'
        '&lon=${location.longitude}',
      );
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final results = jsonDecode(response.body) as List<dynamic>;
        if (results.isNotEmpty) {
          LatLng? nearest;
          double best = double.infinity;
          for (final raw in results) {
            final r = raw as Map<String, dynamic>;
            final lat = double.tryParse(r['lat']?.toString() ?? '');
            final lon = double.tryParse(r['lon']?.toString() ?? '');
            if (lat == null || lon == null) continue;
            final d = _distanceBetween(
                location.latitude, location.longitude, lat, lon);
            if (d < best) {
              best = d;
              nearest = LatLng(lat, lon);
            }
          }
          return nearest;
        }
      }
    } catch (_) {}
    return null;
  }

  double _calculateDangerScore(
      List<LatLng> points, List<DangerZoneModel> zones) {
    if (zones.isEmpty) return 0.0;
    double totalScore = 0.0;
    for (int i = 0; i < points.length; i += 3) {
      final point = points[i];
      for (final zone in zones) {
        final dist = _distanceBetween(
          point.latitude,
          point.longitude,
          zone.lat,
          zone.lng,
        );
        const scoringRadius = AppThresholds.dangerZoneRadiusMeters + 100;
        if (dist < scoringRadius) {
          final severityWeight = _getSeverityWeight(zone.severity);
          final proximityFactor = 1.0 - (dist / scoringRadius);
          totalScore += severityWeight * proximityFactor * proximityFactor;
        }
      }
    }
    return totalScore;
  }

  double _getSeverityWeight(DangerSeverity s) {
    switch (s) {
      case DangerSeverity.critical:
        return 500.0;
      case DangerSeverity.high:
        return 200.0;
      case DangerSeverity.medium:
        return 50.0;
      case DangerSeverity.low:
        return 10.0;
    }
  }

  double _distanceBetween(double lat1, double lon1, double lat2, double lon2) {
    const double p = 0.017453292519943295; // Pi/180
    final double a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742000 * math.asin(math.sqrt(a));
  }

  // Google-precision encoded polyline (matches OSRM's default geometry).
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
}
