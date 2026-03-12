import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/user_service.dart';
import '../services/location_service.dart';
import '../services/emergency_service.dart';
import '../services/risk_analysis_service.dart';
import '../services/danger_zone_service.dart';
import '../services/predictive_danger_service.dart';
import '../services/shake_service.dart';
import '../services/panic_detection_service.dart';
import '../services/motion_detection_service.dart';
import '../services/voice_service.dart';
import '../services/notification_service.dart';
import '../utils/constants.dart';
import '../widgets/sos_button.dart';
import '../widgets/danger_warning_banner.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Timer? _riskTimer;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    final auth = context.read<UserService>();
    // Ensure user data is loaded if coming from a cold start
    if (auth.currentUserModel == null) {
      // For demo purposes, we use the mock ID
      await auth.loadCurrentUser('mock_user_123');
    }
    
    await _initializeServices();
    if (mounted) setState(() => _isInitializing = false);
  }

  Future<void> _initializeServices() async {
    try {
      await context.read<NotificationService>().initialize();
      await context.read<DangerZoneService>().loadDangerZones();
      
      // IMPORTANT: Initialize Voice Service for panic phrase detection
      await context.read<VoiceService>().initialize();

      // Start shake detection
      context.read<ShakeService>().startListening(onShake: _onShakeDetected);

      // Start panic detection (voice + motion)
      context.read<PanicDetectionService>().startDetection(
        voiceService: context.read<VoiceService>(),
        motionService: context.read<MotionDetectionService>(),
        onPanicDetected: _onPanicDetected,
      );

      _startRiskAnalysis();
    } catch (e) {
      debugPrint('Error initializing services: $e');
    }
  }

  void _startRiskAnalysis() {
    _riskTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      try {
        final pos = await context.read<LocationService>().getCurrentPosition();
        if (!mounted) return;
        await context.read<RiskAnalysisService>().analyzeCurrentRisk(
          lat: pos.latitude,
          lng: pos.longitude,
          dangerZoneService: context.read<DangerZoneService>(),
          predictiveService: context.read<PredictiveDangerService>(),
        );
      } catch (_) {}
    });
  }

  void _onShakeDetected() {
    if (context.read<EmergencyService>().isActive) return;
    Navigator.pushNamed(context, AppRoutes.sos);
  }

  void _onPanicDetected(String reason) {
    if (context.read<EmergencyService>().isActive) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⚠️ $reason – Triggering SOS...'),
        backgroundColor: AppColors.danger,
        duration: const Duration(seconds: 2),
      ),
    );
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) Navigator.pushNamed(context, AppRoutes.sos);
    });
  }

  @override
  void dispose() {
    _riskTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    final user = context.watch<UserService>().currentUserModel;
    final riskAnalysis = context.watch<RiskAnalysisService>();
    final emergency = context.watch<EmergencyService>();

    if (emergency.stealthMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.stealthMode, (_) => false);
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _initializeServices,
        child: CustomScrollView(
          slivers: [
            _buildAppBar(user?.name ?? 'User'),
            SliverToBoxAdapter(
              child: Column(
                children: [
                  if (riskAnalysis.shouldWarn)
                    DangerWarningBanner(
                      riskLevel: riskAnalysis.riskLevel,
                      alerts: riskAnalysis.alerts,
                    ),
                  const SizedBox(height: 24),
                  SosButton(
                    onActivate: () => Navigator.pushNamed(context, AppRoutes.sos),
                  ),
                  const SizedBox(height: 32),
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildStatusRow(riskAnalysis),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  SliverAppBar _buildAppBar(String name) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.background,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary.withOpacity(0.2), AppColors.background],
            ),
          ),
          padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hello, ${name.split(' ').first} 👋',
                    style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w600),
                  ),
                  const Text('Stay safe today', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                ],
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    (name.isNotEmpty ? name[0] : 'U').toUpperCase(),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      const _QuickAction(icon: Icons.map_outlined, label: 'Safe Map', color: Color(0xFF1565C0), route: AppRoutes.map),
      const _QuickAction(icon: Icons.directions_walk, label: 'Safe Walk', color: Color(0xFF2E7D32), route: AppRoutes.safeWalk),
      const _QuickAction(icon: Icons.phone_in_talk_outlined, label: 'Fake Call', color: Color(0xFF6A1B9A), route: AppRoutes.fakeCall),
      const _QuickAction(icon: Icons.people_outline, label: 'Guardians', color: Color(0xFFE65100), route: AppRoutes.guardianNetwork),
      const _QuickAction(icon: Icons.report_problem_outlined, label: 'Report', color: Color(0xFFAD1457), route: AppRoutes.report),
      const _QuickAction(icon: Icons.forum_outlined, label: 'Community', color: Color(0xFF00695C), route: AppRoutes.community),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: actions.map((a) => _QuickActionCard(action: a)).toList(),
      ),
    );
  }

  Widget _buildStatusRow(RiskAnalysisService risk) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _StatusCard(
              label: 'Risk Level',
              value: risk.riskLevel,
              icon: Icons.shield_outlined,
              color: risk.riskLevel == 'HIGH' ? AppColors.danger : risk.riskLevel == 'MODERATE' ? AppColors.warning : AppColors.safe,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatusCard(
              label: 'Guardians',
              value: '${context.watch<UserService>().currentUserModel?.guardianIds.length ?? 0}',
              icon: Icons.group_outlined,
              color: AppColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      currentIndex: 0,
      onTap: (i) {
        final routes = [AppRoutes.dashboard, AppRoutes.map, AppRoutes.community, AppRoutes.settings];
        if (i != 0) Navigator.pushNamed(context, routes[i]);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.map_outlined), label: 'Map'),
        BottomNavigationBarItem(icon: Icon(Icons.forum_outlined), label: 'Community'),
        BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: 'Settings'),
      ],
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  const _QuickAction({required this.icon, required this.label, required this.color, required this.route});
}

class _QuickActionCard extends StatelessWidget {
  final _QuickAction action;
  const _QuickActionCard({required this.action});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, action.route),
      child: Container(
        decoration: BoxDecoration(
          color: action.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: action.color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(action.icon, color: action.color, size: 32),
            const SizedBox(height: 6),
            Text(
              action.label,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatusCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
              Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}
