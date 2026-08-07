import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:latlong2/latlong.dart';

import '../models/danger_zone_model.dart';
import '../services/location_service.dart';
import '../services/route_safety_service.dart';
import '../services/danger_zone_service.dart';
import '../services/emergency_service.dart';
import '../utils/constants.dart';
import '../widgets/real_map.dart';
import '../widgets/danger_warning_banner.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final TextEditingController _searchCtrl = TextEditingController();

  LatLng? _userLocation;
  LatLng? _destination;
  List<DangerZoneData> _dangerZones = [];
  List<RealMapMarker> _markers = [];
  List<LatLng> _polylines = [];
  bool _isLoading = true;
  bool _inDanger = false;
  bool _followUser = false;
  bool _isCalculating = false;
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    Position? pos;
    try {
      pos = await context.read<LocationService>().getCurrentPosition();
    } catch (_) {
      pos = null;
    }
    if (!mounted) return;
    if (pos != null) {
      final p = pos;
      setState(() {
        _userLocation = LatLng(p.latitude, p.longitude);
        _isLoading = false;
      });
      _startLocationListening();
      await _loadDangerZones(p);
    } else {
      setState(() {
        _userLocation = const LatLng(28.6139, 77.2090); // New Delhi fallback
        _isLoading = false;
      });
      _startLocationListening();
      await _loadDangerZones(_fallbackPosition());
    }
  }

  Position _fallbackPosition() {
    return Position(
      latitude: 28.6139,
      longitude: 77.2090,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  Future<void> _loadDangerZones(Position pos) async {
    final dzService = context.read<DangerZoneService>();
    await dzService.loadDangerZones();
    if (!mounted) return;
    final zones = dzService.dangerZones
        .map((z) => DangerZoneData(
              center: LatLng(z.lat, z.lng),
              radiusMeters: AppThresholds.dangerZoneRadiusMeters,
              color: _severityToColor(z.severity),
            ))
        .toList();
    setState(() => _dangerZones = zones);
    final inDanger = await dzService.checkUserInDangerZone(pos);
    if (!mounted) return;
    setState(() => _inDanger = inDanger);
  }

  Future<void> _calculateSafePath() async {
    if (_userLocation == null || _destination == null) return;
    setState(() => _isCalculating = true);
    try {
      final zones = context.read<DangerZoneService>().dangerZones;
      final points =
          await context.read<RouteSafetyService>().calculateSafeRoute(
                origin: _userLocation!,
                destination: _destination!,
                dangerZones: zones,
              );
      if (!mounted) return;
      setState(() {
        _isCalculating = false;
        _polylines = points;
        _markers = [
          RealMapMarker(
            point: _destination!,
            color: AppColors.safe,
            icon: Icons.flag,
          ),
        ];
      });
      if (points.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No safe route found.')),
        );
      } else {
        _frameMapTo([_userLocation!, _destination!]);
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
    _positionSub?.cancel();
    _positionSub = context.read<LocationService>().positionStream.listen((pos) {
      if (!mounted) return;
      setState(() => _userLocation = LatLng(pos.latitude, pos.longitude));
      if (_followUser) {
        _mapController.move(_userLocation!, 15);
      }
    });
  }

  void _fitOnUser() {
    final loc = _userLocation;
    if (loc == null) return;
    _mapController.move(loc, 15);
  }

  void _frameMapTo(List<LatLng> points) {
    if (points.isEmpty || !mounted) return;
    try {
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(90),
        ),
      );
    } catch (_) {
      if (points.isNotEmpty) {
        _mapController.move(points.first, 13);
      }
    }
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
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
          title: const Text('Safety Map'),
          actions: [
            IconButton(
              icon: Icon(
                _followUser ? Icons.gps_fixed : Icons.gps_not_fixed,
                color: _followUser ? AppColors.primary : null,
              ),
              onPressed: () {
                setState(() => _followUser = !_followUser);
                if (_followUser) _fitOnUser();
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
                  riskLevel: 'HIGH', alerts: ['You are in a danger zone!']),
            Expanded(
              child: _isLoading || _userLocation == null
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: AppColors.primary))
                  : Stack(
                      children: [
                        Positioned.fill(
                          child: RealMap(
                            center: _userLocation!,
                            controller: _mapController,
                            dangerZones: _dangerZones,
                            markers: _markers,
                            polyline: _polylines,
                            userLocation: _userLocation,
                            onTap: (_, latLng) {
                              setState(() {
                                _destination = latLng;
                                _searchCtrl.text = 'Selected Location';
                                _markers = [
                                  RealMapMarker(
                                    point: latLng,
                                    color: AppColors.safe,
                                    icon: Icons.flag,
                                  ),
                                ];
                              });
                              _calculateSafePath();
                            },
                          ),
                        ),
                        Positioned(
                          top: 16,
                          left: 20,
                          right: 20,
                          child: _buildSearchBar(),
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
                            bottom: 100,
                            left: 50,
                            right: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Tap on the map to choose a destination')),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                              ),
                              child: const Text('Set Destination Here',
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        if (_isCalculating)
                          const Center(
                            child: Card(
                              color: AppColors.surface,
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 16),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.safe),
                                    ),
                                    SizedBox(width: 16),
                                    Text('Calculating safest path...',
                                        style: TextStyle(
                                            color: AppColors.textPrimary)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          onPressed: () => Navigator.pushNamed(context, AppRoutes.safeRouteMap),
          icon: const Icon(Icons.navigation_outlined),
          label: const Text('Safe Route'),
        ),
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
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: 'Move map or tap to set destination',
          hintStyle:
              const TextStyle(color: AppColors.textSecondary, fontSize: 13),
          prefixIcon: const Icon(Icons.search, color: AppColors.primary),
          suffixIcon: _destination != null
              ? IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () {
                    setState(() {
                      _destination = null;
                      _polylines = [];
                      _markers = [];
                      _searchCtrl.clear();
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
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
