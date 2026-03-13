import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/location_service.dart';
import '../services/emergency_service.dart';
import '../models/emergency_model.dart';
import '../utils/constants.dart';

/// Guardian's real-time monitoring screen – shows user's live location
/// and active emergency status.
class GuardianMonitorScreen extends StatefulWidget {
  /// The userId of the person being monitored.
  final String? watchedUserId;
  const GuardianMonitorScreen({super.key, this.watchedUserId});

  @override
  State<GuardianMonitorScreen> createState() =>
      _GuardianMonitorScreenState();
}

class _GuardianMonitorScreenState extends State<GuardianMonitorScreen> {
  GoogleMapController? _mapController;
  LatLng? _userLatLng;

  @override
  Widget build(BuildContext context) {
    final uid = widget.watchedUserId ?? 'unknown';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Guardian Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: () {
              if (_userLatLng != null) {
                _mapController?.animateCamera(
                    CameraUpdate.newLatLngZoom(_userLatLng!, 16));
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Emergency status banner
          StreamBuilder<EmergencyModel?>(
            stream: context
                .read<EmergencyService>()
                .streamActiveEmergencyForUser(uid),
            builder: (_, snap) {
              final emergency = snap.data;
              if (emergency == null) {
                return _SafeBanner();
              }
              return _EmergencyBanner(emergency: emergency);
            },
          ),
          // Live map
          Expanded(
            child: StreamBuilder<Map<String, double>?>(
              stream: context
                  .read<LocationService>()
                  .streamUserLocation(uid),
              builder: (_, snap) {
                final geoPoint = snap.data;
                if (geoPoint != null) {
                  _userLatLng = LatLng(
                      geoPoint['lat']!, geoPoint['lng']!);
                  _mapController?.animateCamera(
                      CameraUpdate.newLatLng(_userLatLng!));
                }

                return GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _userLatLng ??
                        const LatLng(28.6139, 77.2090),
                    zoom: 15,
                  ),
                  myLocationEnabled: false,
                  markers: _userLatLng != null
                      ? {
                          Marker(
                            markerId: const MarkerId('user'),
                            position: _userLatLng!,
                            icon:
                                BitmapDescriptor.defaultMarkerWithHue(
                                    BitmapDescriptor.hueRed),
                            infoWindow: const InfoWindow(
                                title: 'Protected User'),
                          ),
                        }
                      : {},
                  onMapCreated: (c) => _mapController = c,
                  style: _darkMapStyle,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static const _darkMapStyle = '''[{"elementType":"geometry","stylers":[{"color":"#212121"}]},
{"elementType":"labels.text.fill","stylers":[{"color":"#757575"}]},
{"featureType":"road","elementType":"geometry","stylers":[{"color":"#2c2c2c"}]},
{"featureType":"water","elementType":"geometry","stylers":[{"color":"#000000"}]}]''';
}

class _SafeBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      color: AppColors.safe.withOpacity(0.15),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, color: AppColors.safe, size: 18),
          SizedBox(width: 8),
          Text('No active emergency – User is safe',
              style: TextStyle(color: AppColors.safe, fontSize: 13)),
        ],
      ),
    );
  }
}

class _EmergencyBanner extends StatelessWidget {
  final EmergencyModel emergency;
  const _EmergencyBanner({required this.emergency});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      color: AppColors.danger.withOpacity(0.2),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning_rounded,
                  color: AppColors.danger, size: 20),
              SizedBox(width: 8),
              Text('🚨 ACTIVE EMERGENCY',
                  style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 14,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Triggered by: ${emergency.triggeredBy.name.toUpperCase()}  •  '
            '${emergency.createdAt.hour}:${emergency.createdAt.minute.toString().padLeft(2, "0")}',
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          if (emergency.livestreamUrl != null) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () {},
              child: const Text(
                '📹 Live stream available – Tap to watch',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    decoration: TextDecoration.underline),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
