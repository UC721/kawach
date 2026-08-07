import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../utils/constants.dart';

/// A real "danger zone" circle overlay on the map.
class DangerZoneData {
  final LatLng center;
  final double radiusMeters;
  final Color color;
  const DangerZoneData({
    required this.center,
    required this.radiusMeters,
    required this.color,
  });
}

/// A map pin that draws itself from its own [IconData]/[Color].
class RealMapMarker {
  final LatLng point;
  final Color color;
  final IconData? icon;
  final String? label;
  const RealMapMarker({
    required this.point,
    required this.color,
    this.icon,
    this.label,
  });
}

/// A real, free, no-API-key map backed by OpenStreetMap tiles (flutter_map).
///
/// Renders the live map (not a demo canvas) with optional danger circles, a
/// safe-route polyline and markers. Coordinates are lat/lng so it works
/// identically on web, Android and iOS.
class RealMap extends StatefulWidget {
  final LatLng center;
  final double zoom;
  final MapController? controller;
  final List<DangerZoneData> dangerZones;
  final List<RealMapMarker> markers;
  final List<LatLng> polyline;
  final Color polylineColor;
  final LatLng? userLocation;
  final bool interactive;
  final void Function(TapPosition tapPosition, LatLng point)? onTap;

  const RealMap({
    super.key,
    required this.center,
    this.zoom = 13,
    this.controller,
    this.dangerZones = const [],
    this.markers = const [],
    this.polyline = const [],
    this.polylineColor = AppColors.safe,
    this.userLocation,
    this.interactive = true,
    this.onTap,
  });

  @override
  State<RealMap> createState() => _RealMapState();
}

class _RealMapState extends State<RealMap> {
  /// Own controller when the caller does not supply one (self-contained maps).
  late final MapController _internal = widget.controller ?? MapController();

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _internal,
      options: MapOptions(
        initialCenter: widget.center,
        initialZoom: widget.zoom,
        onTap: widget.interactive ? widget.onTap : null,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.kawach',
        ),
        if (widget.dangerZones.isNotEmpty)
          CircleLayer(
            circles: [
              for (final zone in widget.dangerZones)
                CircleMarker(
                  point: zone.center,
                  radius: zone.radiusMeters,
                  useRadiusInMeter: true,
                  color: zone.color.withValues(alpha: 0.18),
                  borderColor: zone.color.withValues(alpha: 0.55),
                  borderStrokeWidth: 2,
                ),
            ],
          ),
        if (widget.polyline.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: widget.polyline,
                strokeWidth: 5,
                color: widget.polylineColor,
              ),
            ],
          ),
        MarkerLayer(
          markers: [
            if (widget.userLocation != null)
              Marker(
                point: widget.userLocation!,
                width: 44,
                height: 44,
                child: const _UserBadge(),
              ),
            for (final marker in widget.markers)
              Marker(
                point: marker.point,
                width: 40,
                height: 40,
                child: _MarkerPin(marker: marker),
              ),
          ],
        ),
      ],
    );
  }
}

class _UserBadge extends StatelessWidget {
  const _UserBadge();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: const BoxDecoration(
            color: Color(0xFF4A90E2),
            shape: BoxShape.circle,
            border: Border.fromBorderSide(
              BorderSide(color: Colors.white, width: 2),
            ),
          ),
        ),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: const Color(0xFF4A90E2).withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

class _MarkerPin extends StatelessWidget {
  final RealMapMarker marker;
  const _MarkerPin({required this.marker});

  @override
  Widget build(BuildContext context) {
    final color = marker.color;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            marker.icon ?? Icons.place,
            color: Colors.white,
            size: 14,
          ),
        ),
        if (marker.label != null) ...[
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              marker.label!,
              style: const TextStyle(color: Colors.black, fontSize: 9),
            ),
          ),
        ],
      ],
    );
  }
}
