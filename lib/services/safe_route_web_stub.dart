import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/danger_zone_model.dart';

Future<List<LatLng>> calculateSafeRouteWeb({
  required LatLng origin,
  required LatLng destination,
  required List<DangerZoneModel> dangerZones,
}) async {
  // This will be replaced by the real implementation in the web-specific file
  return [];
}
