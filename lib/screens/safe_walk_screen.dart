import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/ring_coordinator.dart';
import '../services/emergency_service.dart';
import '../services/location_service.dart';
import '../services/audio_service.dart';
import '../services/camera_evidence_service.dart';
import '../services/evidence_vault_service.dart';
import '../services/notification_service.dart';
import '../services/sms_service.dart';
import '../services/live_stream_service.dart';
import '../services/user_service.dart';
import '../services/offline_emergency_service.dart';
import '../services/guardian_network_service.dart';
import '../models/emergency_model.dart';
import '../utils/constants.dart';

class SafeWalkScreen extends StatefulWidget {
  const SafeWalkScreen({super.key});

  @override
  State<SafeWalkScreen> createState() => _SafeWalkScreenState();
}

class _SafeWalkScreenState extends State<SafeWalkScreen> {
  int _remainingSeconds = AppThresholds.safeWalkDefaultSeconds;
  Timer? _walkTimer;
  bool _isActive = false;
  bool _expired = false;

  void _startWalk() {
    setState(() {
      _isActive = true;
      _remainingSeconds = AppThresholds.safeWalkDefaultSeconds;
    });

    _walkTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _onTimerExpired();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _confirmArrival() {
    _walkTimer?.cancel();
    setState(() { _isActive = false; _expired = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ Safe arrival confirmed! Guardians notified.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _onTimerExpired() async {
    setState(() { _expired = true; _isActive = false; });
    // Auto-trigger SOS
    await context.read<EmergencyService>().triggerEmergency(
      trigger: EmergencyTrigger.safeWalkTimeout,
      locationService: context.read<LocationService>(),
      audioService: context.read<AudioService>(),
      cameraService: context.read<CameraEvidenceService>(),
      vaultService: context.read<EvidenceVaultService>(),
      notificationService: context.read<NotificationService>(),
      smsService: context.read<SmsService>(),
      streamService: context.read<LiveStreamService>(),
      userService: context.read<UserService>(),
      offlineService: context.read<OfflineEmergencyService>(),
      ringCoordinator: context.read<RingCoordinator>(),
      guardianNetworkService: context.read<GuardianNetworkService>(),
    );
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(
          context, AppRoutes.emergencyDashboard, (_) => false);
    }
  }

  @override
  void dispose() {
    _walkTimer?.cancel();
    super.dispose();
  }

  String _formatTime(int secs) {
    final m = (secs ~/ 60).toString().padLeft(2, '0');
    final s = (secs % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Safe Walk Mode')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                children: [
                  Icon(Icons.directions_walk,
                      size: 48, color: AppColors.safe),
                  SizedBox(height: 12),
                  Text(
                    'Safe Walk',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Set your walk time. If you don\'t confirm arrival, SOS will auto-trigger.',
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            // Timer display
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isActive
                    ? AppColors.safe.withOpacity(0.1)
                    : AppColors.surfaceVariant,
                border: Border.all(
                  color: _isActive
                      ? AppColors.safe
                      : AppColors.cardBorder,
                  width: 3,
                ),
              ),
              child: Center(
                child: Text(
                  _formatTime(_remainingSeconds),
                  style: TextStyle(
                    color: _isActive ? AppColors.safe : Colors.white54,
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            // Duration slider
            if (!_isActive) ...[
              Text(
                'Walk Duration: ${_formatTime(_remainingSeconds)}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              Slider(
                value: _remainingSeconds.toDouble(),
                min: 300,
                max: 7200,
                divisions: 23,
                activeColor: AppColors.primary,
                inactiveColor: AppColors.surfaceVariant,
                onChanged: (v) =>
                    setState(() => _remainingSeconds = v.toInt()),
              ),
            ],
            const Spacer(),
            if (!_isActive)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _startWalk,
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Start Safe Walk'),
                ),
              ),
            if (_isActive) ...[
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.safe),
                  onPressed: _confirmArrival,
                  icon: const Icon(Icons.check_circle_outline,
                      color: Colors.black),
                  label: const Text("I've Arrived Safely",
                      style: TextStyle(color: Colors.black)),
                ),
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
