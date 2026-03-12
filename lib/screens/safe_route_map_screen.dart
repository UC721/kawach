import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/location_service.dart';
import '../services/route_safety_service.dart';
import '../services/danger_zone_service.dart';
import '../utils/constants.dart';

class SafeRouteMapScreen extends StatefulWidget {
  final LatLng? destination;
  const SafeRouteMapScreen({super.key, this.destination});

  @override
  State<SafeRouteMapScreen> createState() => _SafeRouteMapScreenState();
}

class _SafeRouteMapScreenState extends State<SafeRouteMapScreen> {
  GoogleMapController? _mapController;
  LatLng? _origin;
  LatLng? _destination;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final pos = await context.read<LocationService>().getCurrentPosition();
      setState(() {
        _origin = LatLng(pos.latitude, pos.longitude);
        _destination = widget.destination;
      });
      if (_destination != null) await _calculateRoute();
    } catch (_) {}
  }

  Future<void> _calculateRoute() async {
    if (_origin == null || _destination == null) return;
    setState(() => _loading = true);

    final zones = context.read<DangerZoneService>().dangerZones;
    final polyline = await context.read<RouteSafetyService>().calculateSafeRoute(
          origin: _origin!,
          destination: _destination!,
          dangerZones: zones,
        );

    if (polyline.isNotEmpty) {
      setState(() {
        _polylines = {
          Polyline(
            polylineId: const PolylineId('safe_route'),
            points: polyline,
            color: AppColors.safe,
            width: 5,
          ),
        };
        _markers = {
          Marker(
              markerId: const MarkerId('origin'),
              position: _origin!,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueBlue),
              infoWindow: const InfoWindow(title: 'You are here')),
          Marker(
              markerId: const MarkerId('dest'),
              position: _destination!,
              icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen),
              infoWindow: const InfoWindow(title: 'Destination')),
        };
      });
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Safe Route'),
        actions: [
          if (_loading)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
                target: _origin ?? const LatLng(28.6139, 77.2090),
                zoom: 14),
            myLocationEnabled: true,
            polylines: _polylines,
            markers: _markers,
            onMapCreated: (c) => _mapController = c,
            onLongPress: (latLng) {
              setState(() => _destination = latLng);
              _calculateRoute();
            },
          ),
          if (_destination == null)
            Positioned(
              bottom: 80,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.touch_app_outlined,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Long press on map to set destination',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          // Find safe places buttons
          Positioned(
            top: 16,
            right: 16,
            child: Column(
              children: [
                _SafePlaceBtn(
                  icon: Icons.local_police_outlined,
                  label: 'Police',
                  onTap: () => _findSafePlace('police'),
                ),
                const SizedBox(height: 8),
                _SafePlaceBtn(
                  icon: Icons.local_hospital_outlined,
                  label: 'Hospital',
                  onTap: () => _findSafePlace('hospital'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _findSafePlace(String type) async {
    if (_origin == null) return;
    final place = await context.read<RouteSafetyService>().findNearestSafePlace(
          location: _origin!,
          type: type,
        );
    if (place != null && mounted) {
      final loc = place['geometry']?['location'];
      if (loc != null) {
        setState(() {
          _destination = LatLng(loc['lat'], loc['lng']);
        });
        await _calculateRoute();
      }
    }
  }
}

class _SafePlaceBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SafePlaceBtn(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 8)
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
