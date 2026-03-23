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
  Set<Circle> _dangerCircles = {};
  bool _loading = false;
  CameraPosition? _currentCameraPosition;
  bool _isCameraMoving = false;

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
    _buildHeatmap(zones);
  }

  void _buildHeatmap(List<DangerZoneModel> zones) {
    final circles = <Circle>{};
    for (final zone in zones) {
      final color = _severityToColor(zone.severity);
      for (int i = 1; i <= 3; i++) {
        circles.add(Circle(
          circleId: CircleId('${zone.zoneId}_$i'),
          center: LatLng(zone.lat, zone.lng),
          radius: AppThresholds.dangerZoneRadiusMeters * (i / 3),
          fillColor: color.withOpacity(0.15 * (4 - i)),
          strokeWidth: 0,
        ));
      }
      circles.add(Circle(
        circleId: CircleId('${zone.zoneId}_border'),
        center: LatLng(zone.lat, zone.lng),
        radius: AppThresholds.dangerZoneRadiusMeters,
        fillColor: Colors.transparent,
        strokeColor: color.withOpacity(0.5),
        strokeWidth: 2,
      ));
    }
    setState(() => _dangerCircles = circles);
  }

  Color _severityToColor(DangerSeverity s) {
    switch (s) {
      case DangerSeverity.critical: return const Color(0xFF9C27B0);
      case DangerSeverity.high: return const Color(0xFFF44336);
      case DangerSeverity.medium: return const Color(0xFFFF9800);
      case DangerSeverity.low: return const Color(0xFF4CAF50);
    }
  }

  @override
  Widget build(BuildContext context) {
    final emergency = context.watch<EmergencyService>();
    if (emergency.stealthMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.stealthMode, (_) => false);
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
      },
      child: Scaffold(
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
            circles: _dangerCircles,
            onMapCreated: (c) => _mapController = c,
            onCameraMoveStarted: () => setState(() => _isCameraMoving = true),
            onCameraMove: (pos) => _currentCameraPosition = pos,
            onCameraIdle: () => setState(() => _isCameraMoving = false),
            onTap: (latLng) {
              setState(() => _destination = latLng);
              _calculateRoute();
            },
            style: _mapStyle,
          ),
          
          // Central Crosshair Pin
          if (_destination == null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 35),
                child: Icon(
                  Icons.location_on_rounded,
                  size: 44,
                  color: _isCameraMoving ? AppColors.primary.withOpacity(0.7) : AppColors.primary,
                ),
              ),
            ),

          if (_destination == null && !_isCameraMoving)
            Positioned(
              bottom: 120,
              left: 50,
              right: 50,
              child: ElevatedButton(
                onPressed: () {
                  if (_currentCameraPosition != null) {
                    setState(() => _destination = _currentCameraPosition!.target);
                    _calculateRoute();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Confirm Destination', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          if (_destination == null && _isCameraMoving)
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
                    Icon(Icons.gps_fixed,
                        color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Move map to your destination...',
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

  static const _mapStyle = '''[{"elementType":"geometry","stylers":[{"color":"#212121"}]},
{"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
{"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
{"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
{"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c2c2c"}]},
{"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]}]''';
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
