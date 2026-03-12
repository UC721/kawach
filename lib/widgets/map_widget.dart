import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


/// Reusable Google Map widget with optional heatmap circles and markers.
class MapWidget extends StatefulWidget {
  final LatLng initialPosition;
  final double initialZoom;
  final Set<Circle> circles;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final bool myLocationEnabled;
  final void Function(GoogleMapController)? onMapCreated;

  const MapWidget({
    super.key,
    required this.initialPosition,
    this.initialZoom = 14,
    this.circles = const {},
    this.markers = const {},
    this.polylines = const {},
    this.myLocationEnabled = true,
    this.onMapCreated,
  });

  @override
  State<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends State<MapWidget> {
  static const _darkStyle = '''[
{"elementType":"geometry","stylers":[{"color":"#212121"}]},
{"elementType":"labels.icon","stylers":[{"visibility":"off"}]},
{"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
{"elementType":"labels.text.stroke","stylers":[{"color":"#212121"}]},
{"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c2c2c"}]},
{"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]}
]''';

  @override
  Widget build(BuildContext context) {
    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: widget.initialPosition,
        zoom: widget.initialZoom,
      ),
      myLocationEnabled: widget.myLocationEnabled,
      myLocationButtonEnabled: false,
      circles: widget.circles,
      markers: widget.markers,
      polylines: widget.polylines,
      mapType: MapType.normal,
      compassEnabled: false,
      zoomControlsEnabled: false,
      style: _darkStyle,
      onMapCreated: widget.onMapCreated,
    );
  }
}
