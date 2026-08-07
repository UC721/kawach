import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

import '../services/location_service.dart';
import '../services/route_safety_service.dart';
import '../services/danger_zone_service.dart';
import '../models/danger_zone_model.dart';
import '../services/emergency_service.dart';
import '../utils/constants.dart';
import '../widgets/real_map.dart';

class SafeRouteMapScreen extends StatefulWidget {
  final LatLng? destination;
  const SafeRouteMapScreen({super.key, this.destination});

  @override
  State<SafeRouteMapScreen> createState() => _SafeRouteMapScreenState();
}

class _SafeRouteMapScreenState extends State<SafeRouteMapScreen> {
  final MapController _mapController = MapController();
  LatLng? _origin;
  LatLng? _destination;
  List<LatLng> _polylines = [];
  List<RealMapMarker> _markers = [];
  List<DangerZoneData> _dangerZones = [];
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
    final polyline =
        await context.read<RouteSafetyService>().calculateSafeRoute(
              origin: _origin!,
              destination: _destination!,
              dangerZones: zones,
            );

    if (mounted) {
      setState(() {
        _polylines = polyline;
        _markers = [
          RealMapMarker(
            point: _origin!,
            color: Colors.blue,
            icon: Icons.person_pin_circle,
          ),
          RealMapMarker(
            point: _destination!,
            color: AppColors.safe,
            icon: Icons.flag,
          ),
        ];
        _dangerZones = [
          for (final zone in zones)
            DangerZoneData(
              center: LatLng(zone.lat, zone.lng),
              radiusMeters: AppThresholds.dangerZoneRadiusMeters,
              color: _severityToColor(zone.severity),
            ),
        ];
        _loading = false;
      });
      _frameRoute();
    }
  }

  void _frameRoute() {
    if (_origin == null || _destination == null) return;
    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([_origin!, _destination!]),
          padding: const EdgeInsets.all(80),
        ),
      );
    } catch (_) {
      _mapController.move(_origin!, 13);
    }
  }

  Color _severityToColor(DangerSeverity s) {
    switch (s) {
      case DangerSeverity.critical:
        return const Color(0xFF9C27B0);
      case DangerSeverity.high:
        return const Color(0xFFF44336);
      case DangerSeverity.medium:
        return const Color(0xFFFF9800);
      case DangerSeverity.low:
        return const Color(0xFF4CAF50);
    }
  }

  @override
  Widget build(BuildContext context) {
    final emergency = context.watch<EmergencyService>();
    if (emergency.stealthMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
            context, AppRoutes.stealthMode, (_) => false);
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context)
            .pushNamedAndRemoveUntil(AppRoutes.dashboard, (route) => false);
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
                        color: AppColors.primary, strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: RealMap(
                center: _origin ?? const LatLng(28.6139, 77.2090),
                controller: _mapController,
                dangerZones: _dangerZones,
                markers: _markers,
                polyline: _polylines,
                userLocation: _origin,
                onTap: (_, latLng) {
                  setState(() => _destination = latLng);
                  _calculateRoute();
                },
              ),
            ),
            if (_destination == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 35),
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 44,
                    color: AppColors.primary,
                  ),
                ),
              ),
            if (_destination == null)
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.touch_app, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Tap on the map to choose your destination',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
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
      setState(() => _destination = place);
      await _calculateRoute();
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
          color: AppColors.surface.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 18),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
