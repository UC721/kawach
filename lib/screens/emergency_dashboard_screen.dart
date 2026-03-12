import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/emergency_service.dart';
import '../services/location_service.dart';
import '../services/audio_service.dart';
import '../services/live_stream_service.dart';
import '../services/siren_service.dart';
import '../utils/constants.dart';

class EmergencyDashboardScreen extends StatelessWidget {
  const EmergencyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final emergency = context.watch<EmergencyService>();
    final location = context.watch<LocationService>();
    final audio = context.watch<AudioService>();
    final stream = context.watch<LiveStreamService>();
    final siren = context.watch<SirenService>();

    return Scaffold(
      backgroundColor: const Color(0xFF1A0000),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.danger.withOpacity(0.3),
                    Colors.transparent
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.warning_rounded,
                      color: AppColors.danger, size: 44),
                  const SizedBox(height: 8),
                  const Text(
                    '🚨 EMERGENCY ACTIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Emergency responders and guardians have been alerted',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 13),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Status cards
                  _StatusIndicatorCard(
                    icon: Icons.location_on_outlined,
                    title: 'Live GPS Tracking',
                    status: location.isTracking ? 'ACTIVE' : 'INACTIVE',
                    active: location.isTracking,
                  ),
                  const SizedBox(height: 12),
                  _StatusIndicatorCard(
                    icon: Icons.mic,
                    title: 'Audio Recording',
                    status: audio.isRecording ? 'RECORDING' : 'INACTIVE',
                    active: audio.isRecording,
                  ),
                  const SizedBox(height: 12),
                  _StatusIndicatorCard(
                    icon: Icons.videocam_outlined,
                    title: 'Live Video Stream',
                    status: stream.isStreaming ? 'STREAMING' : 'INACTIVE',
                    active: stream.isStreaming,
                  ),
                  const SizedBox(height: 12),
                  const _StatusIndicatorCard(
                    icon: Icons.notifications_active,
                    title: 'Guardians Notified',
                    status: 'SENT',
                    active: true,
                  ),
                  const SizedBox(height: 12),
                  const _StatusIndicatorCard(
                    icon: Icons.sms_outlined,
                    title: 'SMS Backup',
                    status: 'SENT',
                    active: true,
                  ),
                  const SizedBox(height: 24),
                  // Location Display
                  if (location.currentPosition != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Current Location',
                              style: TextStyle(
                                  color: Colors.white60, fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            '${location.currentPosition!.latitude.toStringAsFixed(6)}, '
                            '${location.currentPosition!.longitude.toStringAsFixed(6)}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _ActionBtn(
                          icon: siren.isActive
                              ? Icons.volume_off
                              : Icons.volume_up,
                          label: siren.isActive ? 'Stop Siren' : 'Siren',
                          color: AppColors.warning,
                          onTap: () {
                            if (siren.isActive) {
                              siren.stopSiren();
                            } else {
                              siren.startSiren();
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionBtn(
                          icon: Icons.visibility_off,
                          label: 'Stealth',
                          color: AppColors.surfaceVariant,
                          onTap: () => Navigator.pushNamedAndRemoveUntil(
                              context, AppRoutes.stealthMode, (_) => false),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Resolve button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.safe,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text(
                        "I'm Safe – Resolve Emergency",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: () async {
                        await context
                            .read<EmergencyService>()
                            .resolveEmergency(
                          locationService:
                              context.read<LocationService>(),
                          audioService: context.read<AudioService>(),
                          streamService:
                              context.read<LiveStreamService>(),
                        );
                        if (context.mounted) {
                          Navigator.pushNamedAndRemoveUntil(
                              context, AppRoutes.dashboard, (_) => false);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusIndicatorCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String status;
  final bool active;

  const _StatusIndicatorCard({
    required this.icon,
    required this.title,
    required this.status,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color:
              active ? AppColors.primary.withOpacity(0.4) : Colors.white10,
        ),
      ),
      child: Row(
        children: [
          Icon(icon,
              color: active ? AppColors.primary : Colors.white30, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.safe.withOpacity(0.2)
                  : Colors.white10,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: active ? AppColors.safe : Colors.white54,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
