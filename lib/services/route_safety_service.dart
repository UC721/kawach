import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../models/ai_prediction_model.dart';
import '../models/danger_zone_model.dart';
import '../utils/constants.dart';
import 'ai/ai_model_service.dart';
import 'safe_route_web_connector.dart' as web_interop;

class RouteSafetyService extends ChangeNotifier {
  List<LatLng> _safeRoute = [];
  bool _isLoading = false;
  String? _errorMessage;
  AIPrediction? _latestRouteRisk;

  List<LatLng> get safeRoute => _safeRoute;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  AIPrediction? get latestRouteRisk => _latestRouteRisk;

  // ── Calculate safest route avoiding danger zones ─────────────
  Future<List<LatLng>> calculateSafeRoute({
    required LatLng origin,
    required LatLng destination,
    List<DangerZoneModel> dangerZones = const [],
    AIModelService? aiModelService,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Build waypoints to avoid danger zones (simple avoidance)
      final waypointsParam = _buildWaypointAvoidance(
          origin, destination, dangerZones);

      // On Web, direct REST calls to Google Maps are blocked by CORS.
      // We use the JavaScript SDK already loaded in index.html to avoid this.
      if (kIsWeb) {
        final webPoints = await web_interop.calculateSafeRouteWeb(
          origin: origin,
          destination: destination,
          dangerZones: dangerZones,
        );
        _safeRoute = webPoints;
        _isLoading = false;
        notifyListeners();
        return _safeRoute;
      }

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
        final routes = data['routes'] as List<dynamic>;
        
        if (routes.isNotEmpty) {
          // Find the safest route among alternatives
          dynamic safestRoute = routes[0];
          double minDangerScore = double.infinity;

          for (final route in routes) {
            final polylinePoints = _decodePolyline(route['overview_polyline']['points']);
            final score = _calculateDangerScore(polylinePoints, dangerZones);
            
            if (score < minDangerScore) {
              minDangerScore = score;
              safestRoute = route;
            }
          }

          final points = safestRoute['overview_polyline']['points'] as String;
          _safeRoute = _decodePolyline(points);
        }
      } else {
        _errorMessage = 'Route calculation failed';
      }

      // AI: overlay route risk prediction.
      if (aiModelService != null && _safeRoute.isNotEmpty) {
        _latestRouteRisk = aiModelService.predictRouteRisk(
          waypoints: _safeRoute
              .map((p) => {'lat': p.latitude, 'lng': p.longitude})
              .toList(),
          dangerZones: dangerZones,
          hour: DateTime.now().hour,
        );
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

  double _calculateDangerScore(List<LatLng> points, List<DangerZoneModel> zones) {
    if (zones.isEmpty) return 0.0;
    double totalScore = 0.0;

    // We check every few points to save battery/performance while maintaining accuracy
    for (int i = 0; i < points.length; i += 3) {
      final point = points[i];
      for (final zone in zones) {
        final dist = _distanceBetween(
          point.latitude,
          point.longitude,
          zone.lat,
          zone.lng,
        );

        // Radius for scoring is slightly larger than display radius for better avoidance
        const scoringRadius = AppThresholds.dangerZoneRadiusMeters + 100;

        if (dist < scoringRadius) {
          final severityWeight = _getSeverityWeight(zone.severity);
          // Exponential penalty for closer proximity
          final proximityFactor = 1.0 - (dist / scoringRadius);
          totalScore += (severityWeight * proximityFactor * proximityFactor);
        }
      }
    }
    return totalScore;
  }

  double _getSeverityWeight(DangerSeverity s) {
    switch (s) {
      case DangerSeverity.critical: return 500.0; // Extremely high penalty
      case DangerSeverity.high: return 200.0;
      case DangerSeverity.medium: return 50.0;
      case DangerSeverity.low: return 10.0;
    }
  }

  double _distanceBetween(double lat1, double lon1, double lat2, double lon2) {
    // Haversine-like approximation for small distances
    const double p = 0.017453292519943295; // Pi/180
    final double a = 0.5 -
        math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) *
            math.cos(lat2 * p) *
            (1 - math.cos((lon2 - lon1) * p)) /
            2;
    return 12742000 * math.asin(math.sqrt(a)); // 2 * R * asin... R=6371km
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
    // final waypoints = zones.take(5).map((z) => '${z.lat},${z.lng}').join('|');
    return '&avoid=indoor';
  }
}
