import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../services/emergency_service.dart';
import '../services/offline_emergency_service.dart';
import '../utils/constants.dart';

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

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..forward();
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OfflineEmergencyService>().listenForConnectivity();
      context.read<EmergencyService>().restoreActiveEmergency();
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
    Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Positioned(top: -150, left: -100, child: _buildGradientOrb(const Color(0xFFFFCDD2), 400)),
          Positioned(bottom: -100, right: -100, child: _buildGradientOrb(const Color(0xFFE1BEE7), 500)),
          Positioned(top: 200, right: -150, child: _buildGradientOrb(const Color(0xFFBBDEFB), 400)),
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFE53935), Color(0xFF9C27B0)]),
                            boxShadow: [BoxShadow(color: const Color(0xFFE53935).withOpacity(0.3), blurRadius: 40, spreadRadius: 10)],
                          ),
                          child: const Icon(Icons.security_rounded, size: 60, color: Colors.white),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  const Text('KAWACH', style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.textPrimary, letterSpacing: 10)),
                  const SizedBox(height: 12),
                  const Text('Your Shield. Always.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textSecondary, letterSpacing: 4)),
                  const SizedBox(height: 60),
                  SizedBox(width: 30, height: 30, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary.withOpacity(0.4))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientOrb(Color color, double size) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color.withOpacity(0.6), color.withOpacity(0.0)]),
      ),
    );
  }
}
