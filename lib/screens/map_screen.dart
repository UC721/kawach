import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';
import '../services/route_safety_service.dart';
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
  LatLng? _destination;
  Set<Polyline> _polylines = {};
  bool _isLoading = true;
  bool _inDanger = false;
  bool _followUser = false;
  bool _isCalculating = false;
  CameraPosition? _currentCameraPosition;
  bool _isCameraMoving = false;
  final TextEditingController _searchCtrl = TextEditingController();
  StreamSubscription<Position>? _positionSub;

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
      _startLocationListening();
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

  Future<void> _calculateSafePath() async {
    if (_userLocation == null || _destination == null) return;
    
    setState(() => _isCalculating = true);
    try {
      final zones = context.read<DangerZoneService>().dangerZones;
      final points = await context.read<RouteSafetyService>().calculateSafeRoute(
        origin: _userLocation!,
        destination: _destination!,
        dangerZones: zones,
      );

      if (mounted) {
        setState(() {
          _isCalculating = false;
          if (points.isNotEmpty) {
            _polylines = {
              Polyline(
                polylineId: const PolylineId('safe_path'),
                points: points,
                color: AppColors.safe,
                width: 6,
              ),
            };
            _markers.add(Marker(
              markerId: const MarkerId('destination'),
              position: _destination!,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
              infoWindow: const InfoWindow(title: 'Destination Set'),
            ));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('No safe route found or API error occurring.')),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCalculating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _startLocationListening() {
    _positionSub = context.read<LocationService>().positionStream.listen((pos) {
      if (!mounted) return;
      setState(() {
        _userLocation = LatLng(pos.latitude, pos.longitude);
      });
      if (_followUser) {
        _mapController?.animateCamera(
          CameraUpdate.newLatLngZoom(_userLocation!, 15),
        );
      }
      _checkDanger(pos);
    });
  }

  Future<void> _checkDanger(Position pos) async {
    final inDanger = await context.read<DangerZoneService>().checkUserInDangerZone(pos);
    if (!mounted) return;
    setState(() => _inDanger = inDanger);
  }

  void _buildHeatmap(List<DangerZoneModel> zones) {
    final circles = <Circle>{};
    final markers = <Marker>{};

    for (final zone in zones) {
      final color = _severityToColor(zone.severity);
      
      // Heatmap effect: concentric circles with decreasing opacity
      for (int i = 1; i <= 3; i++) {
        circles.add(Circle(
          circleId: CircleId('${zone.zoneId}_$i'),
          center: LatLng(zone.lat, zone.lng),
          radius: AppThresholds.dangerZoneRadiusMeters * (i / 3),
          fillColor: color.withOpacity(0.15 * (4 - i)),
          strokeWidth: 0,
        ));
      }
      
      // Outer border circle
      circles.add(Circle(
        circleId: CircleId('${zone.zoneId}_border'),
        center: LatLng(zone.lat, zone.lng),
        radius: AppThresholds.dangerZoneRadiusMeters,
        fillColor: Colors.transparent,
        strokeColor: color.withOpacity(0.5),
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
        title: const Text('Safety Map'),
        actions: [
          IconButton(
            icon: Icon(
              _followUser ? Icons.gps_fixed : Icons.gps_not_fixed,
              color: _followUser ? AppColors.primary : null,
            ),
            onPressed: () {
              setState(() => _followUser = !_followUser);
              if (_followUser && _userLocation != null) {
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
                    : Stack(
                        children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _userLocation!,
                                zoom: 14,
                              ),
                              myLocationEnabled: true,
                              myLocationButtonEnabled: false,
                              mapType: MapType.normal,
                              circles: _dangerCircles,
                              markers: _markers,
                              polylines: _polylines,
                              onMapCreated: (c) => _mapController = c,
                              onCameraMoveStarted: () => setState(() => _isCameraMoving = true),
                              onCameraMove: (pos) => _currentCameraPosition = pos,
                              onCameraIdle: () => setState(() => _isCameraMoving = false),
                              onTap: (latLng) {
                                setState(() {
                                  _destination = latLng;
                                  _searchCtrl.text = "Selected Location";
                                });
                                _calculateSafePath();
                              },
                              style: _mapStyle, // dark map style
                            ),

                            // Central Crosshair Pin (Uber-style)
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
                            
                            // Floating Search Bar & Status
                            Positioned(
                              top: 60,
                              left: 20,
                              right: 20,
                              child: _buildSearchBar(),
                            ),

                            // Set Destination Button
                            if (_destination == null && !_isCameraMoving)
                              Positioned(
                                bottom: 100,
                                left: 50,
                                right: 50,
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_currentCameraPosition != null) {
                                      setState(() {
                                        _destination = _currentCameraPosition!.target;
                                        _searchCtrl.text = "Searching path...";
                                      });
                                      _calculateSafePath();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                  ),
                                  child: const Text('Set Destination Here', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),

                          // Calculation Overlay
                          if (_isCalculating)
                            const Center(
                              child: Card(
                                color: Colors.black87,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.safe),
                                      ),
                                      SizedBox(width: 16),
                                      Text('Calculating safest path...', style: TextStyle(color: Colors.white)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
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

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Move map or tap to set destination',
          hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _destination != null 
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () {
                    setState(() {
                      _destination = null;
                      _polylines = {};
                      _markers.removeWhere((m) => m.markerId.value == 'destination');
                      _searchCtrl.clear();
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
        onSubmitted: (val) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Search integrated. Now tap on the map to finalize the exact spot!')),
          );
        },
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

  @override
  void dispose() {
    _positionSub?.cancel();
    super.dispose();
  }
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
