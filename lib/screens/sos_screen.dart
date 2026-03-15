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

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _countdownController;
  late Animation<double> _pulseAnim;

  int _countdown = AppThresholds.sosCountdownSeconds;
  Timer? _countdownTimer;
  bool _triggered = false;
  bool _isCancelled = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _countdownController = AnimationController(
      duration: const Duration(seconds: AppThresholds.sosCountdownSeconds),
      vsync: this,
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _startCountdown();
  }

  void _startCountdown() {
    _countdownController.forward();
    _countdownTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isCancelled) {
        timer.cancel();
        return;
      }
      if (_countdown <= 1) {
        timer.cancel();
        _triggerSOS();
      } else {
        setState(() => _countdown--);
      }
    });
  }

  Future<void> _triggerSOS() async {
    if (_triggered || _isCancelled) return;
    setState(() => _triggered = true);

    final emergency = context.read<EmergencyService>();
    await emergency.triggerEmergency(
      trigger: EmergencyTrigger.manual,
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
      Navigator.pushReplacementNamed(
          context, AppRoutes.emergencyDashboard);
    }
  }

  void _cancel() {
    _countdownTimer?.cancel();
    setState(() => _isCancelled = true);
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countdownController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.danger,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFB71C1C), Color(0xFF7B0000)],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Warning icon
              const Icon(
                Icons.warning_rounded,
                size: 60,
                color: Colors.white70,
              ),
              const SizedBox(height: 16),
              const Text(
                'SOS ACTIVATING',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Emergency services will be alerted',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.7), fontSize: 15),
              ),
              const Spacer(),
              // Countdown circle
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (_, __) => Transform.scale(
                  scale: _triggered ? 1.0 : _pulseAnim.value,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.15),
                      border: Border.all(color: Colors.white, width: 4),
                    ),
                    child: Center(
                      child: _triggered
                          ? const CircularProgressIndicator(
                              color: Colors.white)
                          : Text(
                              '$_countdown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 80,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _triggered
                    ? 'ALERTING EMERGENCY CONTACTS...'
                    : 'Tap CANCEL to abort',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
              const Spacer(),
              // Cancel button
              if (!_triggered)
                GestureDetector(
                  onTap: _cancel,
                  child: Container(
                    width: 160,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white54),
                    ),
                    child: const Center(
                      child: Text(
                        'CANCEL',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 64),
            ],
          ),
        ),
      ),
    );
  }
}
