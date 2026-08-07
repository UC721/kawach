import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/emergency_service.dart';
import '../services/offline_emergency_service.dart';
import '../services/onboarding_service.dart';
import '../utils/constants.dart';
import '../widgets/immersive_ui.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _fadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1500))
      ..forward();
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    // Slow orbital spin for the 3D shield rings.
    _spinController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 9000))
      ..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OfflineEmergencyService>().listenForConnectivity();
      context.read<EmergencyService>().restoreActiveEmergency();
      context.read<OnboardingService>().load();
      if (context.read<OfflineEmergencyService>().lastSyncedAt == null) {
        context.read<OfflineEmergencyService>().restoreSyncState();
      }
    });
    Timer(const Duration(milliseconds: 3000), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final emergency = context.read<EmergencyService>();
    if (emergency.isActive) {
      Navigator.pushReplacementNamed(context, AppRoutes.emergencyDashboard);
      return;
    }
    final onboarding = context.read<OnboardingService>();
    if (!onboarding.isComplete) {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      return;
    }
    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AmbientBackground(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TiltCard(
                  maxTilt: 0.22,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: _buildShield(),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 48),
                const Text('KAWACH',
                    style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textPrimary,
                        letterSpacing: 10)),
                const SizedBox(height: 12),
                const Text('Your Shield. Always.',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                        letterSpacing: 4)),
                const SizedBox(height: 60),
                SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary.withValues(alpha: 0.4))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 3D shield: layered rings + a glossy core to fake volume without meshes.
  Widget _buildShield() {
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE53935), Color(0xFF9C27B0)]),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.7), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE53935).withValues(alpha: 0.45),
            blurRadius: 48,
            spreadRadius: 8,
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _spinController,
        builder: (context, child) {
          final t = _spinController.value;
          return Stack(
            fit: StackFit.expand,
            children: [
              // Orbiting highlight arc, gives the "glossy sphere" illusion.
              CustomPaint(
                painter: _OrbitGlowPainter(t: t),
                child: const SizedBox.expand(),
              ),
              const Icon(Icons.security_rounded, size: 62, color: Colors.white),
            ],
          );
        },
      ),
    );
  }
}

/// Paints an orbiting specular highlight so the shield core reads as a glossy
/// 3D sphere rather than a flat circle.
class _OrbitGlowPainter extends CustomPainter {
  _OrbitGlowPainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final angle = t * 3.141592653589793 * 2;
    // Small bright specular dot orbiting just inside the rim.
    final dot = Offset(
      center.dx + radius * 0.72 * math.cos(angle),
      center.dy + radius * 0.72 * math.sin(angle),
    );
    final dotPaint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(
      dot,
      10,
      dotPaint..color = Colors.white.withValues(alpha: 0.28),
    );
    // A faint secondary counter-orbit opposite it.
    final dot2 = Offset(
      center.dx - radius * 0.55 * math.cos(angle),
      center.dy - radius * 0.55 * math.sin(angle),
    );
    canvas.drawCircle(
      dot2,
      6,
      dotPaint..color = Colors.white.withValues(alpha: 0.16),
    );
  }

  @override
  bool shouldRepaint(covariant _OrbitGlowPainter old) => old.t != t;
}
