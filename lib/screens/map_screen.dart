import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';
import '../services/danger_zone_service.dart';
import '../models/danger_zone_model.dart';
import '../utils/constants.dart';
import '../widgets/danger_warning_banner.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _mapController;
  Set<Circle> _dangerCircles = {};
  Set<Marker> _markers = {};
  LatLng? _userLocation;
  bool _isLoading = true;
  bool _inDanger = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final pos = await context.read<LocationService>().getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _userLocation = LatLng(pos.latitude, pos.longitude);
        _isLoading = false;
      });
      await _loadDangerZones(pos);
    } catch (e) {
      if (!mounted) return;
      // Provide a fallback location if permission fails so the map still loads for demo.
      setState(() {
         _userLocation = const LatLng(28.6139, 77.2090); // Default to New Delhi
         _isLoading = false;
      });
      // Optionally load danger zones for fallback location
      await _loadDangerZones(
        Position(latitude: 28.6139, longitude: 77.2090, timestamp: DateTime.now(), accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0)
      );
    }
  }

  Future<void> _loadDangerZones(Position pos) async {
    final dzService = context.read<DangerZoneService>();
    await dzService.loadDangerZones();
    if (!mounted) return;
    _buildHeatmap(dzService.dangerZones);
    final inDanger = await dzService.checkUserInDangerZone(pos);
    if (!mounted) return;
    setState(() => _inDanger = inDanger);
  }

  void _buildHeatmap(List<DangerZoneModel> zones) {
    final circles = <Circle>{};
    final markers = <Marker>{};

    for (final zone in zones) {
      final color = _severityToColor(zone.severity);
      circles.add(Circle(
        circleId: CircleId(zone.zoneId),
        center: LatLng(zone.lat, zone.lng),
        radius: AppThresholds.dangerZoneRadiusMeters,
        fillColor: color.withOpacity(0.25),
        strokeColor: color,
        strokeWidth: 2,
      ));
      markers.add(Marker(
        markerId: MarkerId(zone.zoneId),
        position: LatLng(zone.lat, zone.lng),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          zone.severity == DangerSeverity.critical ||
                  zone.severity == DangerSeverity.high
              ? BitmapDescriptor.hueRed
              : BitmapDescriptor.hueOrange,
        ),
        infoWindow: InfoWindow(
          title: '${_severityLabel(zone.severity)} Zone',
          snippet: '${zone.reportCount} reports',
        ),
      ));
    }

    setState(() {
      _dangerCircles = circles;
      _markers = markers;
    });
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

  String _severityLabel(DangerSeverity s) => s.name.toUpperCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Safety Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (_userLocation != null) {
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(_userLocation!, 15),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.route),
            onPressed: () =>
                Navigator.pushNamed(context, AppRoutes.safeRouteMap),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_inDanger)
            const DangerWarningBanner(
                riskLevel: 'HIGH',
                alerts: ['You are in a danger zone!']),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : _userLocation == null
                    ? const Center(
                        child: Text('Unable to get location',
                            style: TextStyle(color: Colors.white)))
                    : GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _userLocation!,
                          zoom: 14,
                        ),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        mapType: MapType.normal,
                        circles: _dangerCircles,
                        markers: _markers,
                        onMapCreated: (c) => _mapController = c,
                        style: _mapStyle, // dark map style
                      ),
          ),
          _buildLegend(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        onPressed: () =>
            Navigator.pushNamed(context, AppRoutes.safeRouteMap),
        icon: const Icon(Icons.navigation_outlined),
        label: const Text('Safe Route'),
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _LegendItem(color: Color(0xFF4CAF50), label: 'Low'),
          _LegendItem(color: Color(0xFFFF9800), label: 'Medium'),
          _LegendItem(color: Color(0xFFF44336), label: 'High'),
          _LegendItem(color: Color(0xFF9C27B0), label: 'Critical'),
        ],
      ),
    );
  }

  static const _mapStyle = '''[{"elementType":"geometry","stylers":[{"color":"#212121"}]},
{"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
{"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
{"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
{"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c2c2c"}]},
{"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]}]''';
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 14,
            height: 14,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
