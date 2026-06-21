import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/user_service.dart';
import '../services/siren_service.dart';
import '../utils/constants.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with TickerProviderStateMixin {
  int _currentTab = 0;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentTab,
        children: [
          _HomeTab(pulseAnimation: _pulseAnimation, glowAnimation: _glowAnimation),
          _SafetyMapTab(),
          const SizedBox(),
          _CommunityTab(),
          _ProfileTab(),
        ],
      ),
      floatingActionButton: _buildSosFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildSosFAB() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.sos),
          child: Transform.scale(
            scale: _pulseAnimation.value,
            child: Container(
              width: 68, height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                  colors: [Color(0xFFFF1744), Color(0xFFD50000)],
                ),
                boxShadow: [
                  BoxShadow(color: const Color(0xFFFF1744).withOpacity(0.4), blurRadius: 20, spreadRadius: 2),
                ],
              ),
              child: const Center(
                child: Text('SOS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: BottomAppBar(
        color: Colors.transparent, elevation: 0,
        notchMargin: 8,
        shape: const CircularNotchedRectangle(),
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(Icons.home_rounded, 'Home', 0),
              _navItem(Icons.map_outlined, 'Map', 1),
              const SizedBox(width: 48),
              _navItem(Icons.people_outlined, 'Community', 3),
              _navItem(Icons.person_outlined, 'Profile', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isActive = _currentTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isActive ? AppColors.primary : Colors.grey.shade400, size: 24),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: isActive ? AppColors.primary : Colors.grey.shade400, fontSize: 10, fontWeight: isActive ? FontWeight.w700 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// HOME TAB
// ═══════════════════════════════════════════════
class _HomeTab extends StatelessWidget {
  final Animation<double> pulseAnimation;
  final Animation<double> glowAnimation;
  const _HomeTab({required this.pulseAnimation, required this.glowAnimation});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserService>().currentUserModel;
    final name = user?.name ?? 'User';
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, name),
            const SizedBox(height: 20),
            _buildStatusCard(),
            const SizedBox(height: 16),
            _buildQuickActions(context),
            const SizedBox(height: 24),
            _buildSafetyMapPreview(context),
            const SizedBox(height: 16),
            _buildFeatureGrid(context),
            const SizedBox(height: 20),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String name) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, ${name.split(' ').first} 👋',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary, letterSpacing: -0.5)),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C853).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF00C853).withOpacity(0.3)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded, size: 14, color: Color(0xFF00C853)),
                    SizedBox(width: 4),
                    Text('Protection Active', style: TextStyle(fontSize: 12, color: Color(0xFF00C853), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
        Row(children: [
          _headerIcon(Icons.notifications_outlined, () {}),
          const SizedBox(width: 8),
          _headerIcon(Icons.settings_outlined, () => Navigator.pushNamed(context, AppRoutes.settings)),
        ]),
      ],
    );
  }

  Widget _headerIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white, shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
    );
  }

  Widget _buildStatusCard() {
    return AnimatedBuilder(
      animation: glowAnimation,
      builder: (context, _) {
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Colors.white,
            border: Border.all(color: const Color(0xFF00C853).withOpacity(glowAnimation.value * 0.4)),
            boxShadow: [
              BoxShadow(color: const Color(0xFF00C853).withOpacity(glowAnimation.value * 0.08), blurRadius: 30, spreadRadius: -5),
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(children: [
            Row(children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00C853).withOpacity(0.1),
                ),
                child: const Icon(Icons.security_rounded, color: Color(0xFF00C853), size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('All Systems Active', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('Shake, voice & motion detection ON', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ]),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF00C853).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: const Text('SAFE', style: TextStyle(color: Color(0xFF00C853), fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
              ),
            ]),
            const SizedBox(height: 16),
            Row(children: [
              _miniStatus(Icons.vibration, 'Shake', true),
              _miniStatus(Icons.mic, 'Voice', true),
              _miniStatus(Icons.screen_rotation, 'Motion', true),
              _miniStatus(Icons.wifi, 'Network', true),
            ]),
          ]),
        );
      },
    );
  }

  Widget _miniStatus(IconData icon, String label, bool active) {
    return Expanded(child: Column(children: [
      Icon(icon, color: active ? const Color(0xFF00C853) : Colors.grey.shade300, size: 18),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(color: active ? AppColors.textSecondary : Colors.grey.shade300, fontSize: 10)),
    ]));
  }

  Widget _buildQuickActions(BuildContext context) {
    return Row(children: [
      _quickAction(Icons.phone_outlined, 'Fake\nCall', const Color(0xFF7C4DFF), () => Navigator.pushNamed(context, AppRoutes.fakeCall)),
      const SizedBox(width: 12),
      _quickAction(Icons.volume_up_outlined, 'Alarm\nSiren', const Color(0xFFFF6D00), () {
        try { context.read<SirenService>().toggleSiren(); } catch (_) {}
      }),
      const SizedBox(width: 12),
      _quickAction(Icons.group_outlined, 'Guardian\nNetwork', const Color(0xFF00BFA5), () => Navigator.pushNamed(context, AppRoutes.guardianNetwork)),
      const SizedBox(width: 12),
      _quickAction(Icons.directions_walk_outlined, 'Safe\nWalk', const Color(0xFF2979FF), () => Navigator.pushNamed(context, AppRoutes.safeWalk)),
    ]);
  }

  Widget _quickAction(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    ));
  }

  Widget _buildSafetyMapPreview(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final s = context.findAncestorStateOfType<_DashboardScreenState>();
        s?.setState(() => s._currentTab = 1);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20), color: Colors.white,
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text('Safety Map', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('View Full Map', style: TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.textSecondary),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
            child: SizedBox(height: 160, width: double.infinity, child: CustomPaint(painter: _SafetyMapPainter())),
          ),
        ]),
      ),
    );
  }

  Widget _buildFeatureGrid(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Features', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      Row(children: [
        _featureCard(Icons.report_outlined, 'Report\nIncident', const Color(0xFFFF5252), () => Navigator.pushNamed(context, AppRoutes.report)),
        const SizedBox(width: 12),
        _featureCard(Icons.visibility_outlined, 'Guardian\nMonitor', const Color(0xFF448AFF), () => Navigator.pushNamed(context, AppRoutes.guardianMonitor)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        _featureCard(Icons.warning_amber_outlined, 'Risk\nAlerts', const Color(0xFFFFAB00), () => Navigator.pushNamed(context, AppRoutes.riskAlert)),
        const SizedBox(width: 12),
        _featureCard(Icons.visibility_off_outlined, 'Stealth\nMode', const Color(0xFF26A69A), () => Navigator.pushNamed(context, AppRoutes.stealthMode)),
      ]),
    ]);
  }

  Widget _featureCard(IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade300),
        ]),
      ),
    ));
  }

  Widget _buildRecentActivity() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Recent Activity', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
      const SizedBox(height: 12),
      _activityItem(Icons.check_circle_outline, 'Protection activated', '2 min ago', const Color(0xFF00C853)),
      _activityItem(Icons.location_on_outlined, 'Location tracking enabled', '5 min ago', const Color(0xFF2979FF)),
      _activityItem(Icons.shield_outlined, 'All guardians synced', '10 min ago', const Color(0xFF7C4DFF)),
    ]);
  }

  Widget _activityItem(IconData icon, String text, String time, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
        Text(time, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════
// SAFETY MAP TAB
// ═══════════════════════════════════════════════
class _SafetyMapTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Safety Map', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.safeRouteMap),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.route, size: 16, color: AppColors.primary),
                SizedBox(width: 4),
                Text('Safe Route', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ]),
      ),
      Expanded(
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20), color: Colors.white,
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(children: [
              CustomPaint(painter: _FullSafetyMapPainter(), size: Size.infinite),
              Positioned(top: 12, left: 12, child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _legendItem(const Color(0xFFFF1744), 'Danger Zone'),
                  const SizedBox(height: 6),
                  _legendItem(const Color(0xFFFFAB00), 'Caution Area'),
                  const SizedBox(height: 6),
                  _legendItem(const Color(0xFF00C853), 'Safe Zone'),
                  const SizedBox(height: 6),
                  _legendItem(const Color(0xFF2979FF), 'Police Station'),
                ]),
              )),
            ]),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Row(children: [
          _mapInfoCard(Icons.local_police, 'Nearby\nPolice', '2 stations', Colors.blue),
          const SizedBox(width: 12),
          _mapInfoCard(Icons.local_hospital, 'Nearby\nHospitals', '3 found', Colors.red),
          const SizedBox(width: 12),
          _mapInfoCard(Icons.lightbulb, 'Streetlight\nCoverage', '87%', Colors.orange),
        ]),
      ),
    ]));
  }

  Widget _legendItem(Color color, String text) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
    ]);
  }

  Widget _mapInfoCard(IconData icon, String title, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(title, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary, fontSize: 10, fontWeight: FontWeight.w600)),
        Text(value, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
      ]),
    ));
  }
}

// ═══════════════════════════════════════════════
// COMMUNITY TAB
// ═══════════════════════════════════════════════
class _CommunityTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(child: Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Community Safety', style: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, AppRoutes.report),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add, size: 16, color: AppColors.primary),
                SizedBox(width: 4),
                Text('Report', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ]),
            ),
          ),
        ]),
      ),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withOpacity(0.12)),
        ),
        child: const Row(children: [
          Icon(Icons.people_outline, color: AppColors.primary, size: 24),
          SizedBox(width: 12),
          Expanded(child: Text('Real-time community incident reports near you', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
        ]),
      ),
      Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.shield_outlined, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        const Text('No incidents reported yet', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
        const SizedBox(height: 8),
        Text('Your area is safe!', style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, AppRoutes.report),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.primary.withOpacity(0.3))),
            child: const Text('Report an Incident', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ),
      ]))),
    ]));
  }
}

// ═══════════════════════════════════════════════
// PROFILE TAB
// ═══════════════════════════════════════════════
class _ProfileTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserService>().currentUserModel;
    return SafeArea(child: SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
      child: Column(children: [
        const SizedBox(height: 20),
        CircleAvatar(
          radius: 44, backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text((user?.name.isNotEmpty == true ? user!.name[0] : 'U').toUpperCase(),
            style: const TextStyle(color: AppColors.primary, fontSize: 36, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 12),
        Text(user?.name ?? 'User', style: const TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700)),
        Text(user?.email ?? '', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 24),
        _profileMenuItem(Icons.person_outlined, 'Edit Profile', () => Navigator.pushNamed(context, AppRoutes.profile)),
        _profileMenuItem(Icons.shield_outlined, 'Guardian Network', () => Navigator.pushNamed(context, AppRoutes.guardianNetwork)),
        _profileMenuItem(Icons.settings_outlined, 'Settings', () => Navigator.pushNamed(context, AppRoutes.settings)),
        _profileMenuItem(Icons.history, 'Emergency History', () => Navigator.pushNamed(context, AppRoutes.emergencyDashboard)),
        _profileMenuItem(Icons.info_outline, 'About KAWACH', () {}),
        const SizedBox(height: 24),
        const Text('KAWACH v1.0.0', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
      ]),
    ));
  }

  Widget _profileMenuItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6)],
        ),
        child: Row(children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14))),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade300),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// MAP PAINTERS (light theme)
// ═══════════════════════════════════════════════
class _SafetyMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFFEEF2F7));
    final gridPaint = Paint()..color = Colors.grey.withOpacity(0.15)..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 30) canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    for (double y = 0; y < size.height; y += 30) canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.4), 40, Paint()..color = const Color(0xFFFF1744).withOpacity(0.12));
    final routePaint = Paint()..color = const Color(0xFF00C853)..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(size.width * 0.15, size.height * 0.8)..quadraticBezierTo(size.width * 0.4, size.height * 0.3, size.width * 0.85, size.height * 0.25);
    canvas.drawPath(path, routePaint);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.8), 5, Paint()..color = const Color(0xFF2979FF));
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.8), 8, Paint()..color = const Color(0xFF2979FF).withOpacity(0.3));
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.25), 5, Paint()..color = const Color(0xFF00C853));
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _FullSafetyMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFFEEF2F7));
    final gridPaint = Paint()..color = Colors.grey.withOpacity(0.1)..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    for (double y = 0; y < size.height; y += 40) canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    final roadPaint = Paint()..color = Colors.grey.withOpacity(0.2)..strokeWidth = 2;
    canvas.drawLine(Offset(0, size.height * 0.3), Offset(size.width, size.height * 0.3), roadPaint);
    canvas.drawLine(Offset(0, size.height * 0.6), Offset(size.width, size.height * 0.6), roadPaint);
    canvas.drawLine(Offset(size.width * 0.3, 0), Offset(size.width * 0.3, size.height), roadPaint);
    canvas.drawLine(Offset(size.width * 0.7, 0), Offset(size.width * 0.7, size.height), roadPaint);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.2), 50, Paint()..color = const Color(0xFFFF1744).withOpacity(0.1));
    canvas.drawCircle(Offset(size.width * 0.75, size.height * 0.7), 60, Paint()..color = const Color(0xFFFF1744).withOpacity(0.08));
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.4), 40, Paint()..color = const Color(0xFFFFAB00).withOpacity(0.08));
    canvas.drawCircle(Offset(size.width * 0.4, size.height * 0.8), 45, Paint()..color = const Color(0xFF00C853).withOpacity(0.08));
    _drawMarker(canvas, Offset(size.width * 0.3, size.height * 0.3), const Color(0xFF2979FF));
    _drawMarker(canvas, Offset(size.width * 0.6, size.height * 0.5), const Color(0xFF2979FF));
    _drawMarker(canvas, Offset(size.width * 0.8, size.height * 0.3), const Color(0xFFFF5252));
    final routePaint = Paint()..color = const Color(0xFF00C853)..strokeWidth = 3..style = PaintingStyle.stroke..strokeCap = StrokeCap.round;
    final path = Path()..moveTo(size.width * 0.5, size.height * 0.85)..quadraticBezierTo(size.width * 0.35, size.height * 0.55, size.width * 0.5, size.height * 0.35)..quadraticBezierTo(size.width * 0.6, size.height * 0.2, size.width * 0.7, size.height * 0.15);
    canvas.drawPath(path, routePaint);
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.85), 8, Paint()..color = const Color(0xFF2979FF).withOpacity(0.3));
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.85), 5, Paint()..color = const Color(0xFF2979FF));
  }
  void _drawMarker(Canvas canvas, Offset pos, Color color) {
    canvas.drawCircle(pos, 6, Paint()..color = color.withOpacity(0.3));
    canvas.drawCircle(pos, 3, Paint()..color = color);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
