import 'package:flutter/material.dart';

import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/sos_screen.dart';
import 'screens/map_screen.dart';
import 'screens/safe_route_map_screen.dart';
import 'screens/safe_walk_screen.dart';
import 'screens/fake_call_screen.dart';
import 'screens/guardian_monitor_screen.dart';
import 'screens/report_screen.dart';
import 'screens/community_screen.dart';
import 'screens/stealth_mode_screen.dart';
import 'screens/emergency_dashboard_screen.dart';
import 'screens/guardian_network_screen.dart';
import 'screens/risk_alert_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/settings_screen.dart';
import 'utils/constants.dart';

class KawachApp extends StatelessWidget {
  const KawachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KAWACH',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      initialRoute: AppRoutes.splash,
      routes: {
        AppRoutes.splash: (_) => const SplashScreen(),
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.dashboard: (_) => const DashboardScreen(),
        AppRoutes.sos: (_) => const SosScreen(),
        AppRoutes.map: (_) => const MapScreen(),
        AppRoutes.safeRouteMap: (_) => const SafeRouteMapScreen(),
        AppRoutes.safeWalk: (_) => const SafeWalkScreen(),
        AppRoutes.fakeCall: (_) => const FakeCallScreen(),
        AppRoutes.guardianMonitor: (_) => const GuardianMonitorScreen(),
        AppRoutes.report: (_) => const ReportScreen(),
        AppRoutes.community: (_) => const CommunityScreen(),
        AppRoutes.stealthMode: (_) => const StealthModeScreen(),
        AppRoutes.emergencyDashboard: (_) => const EmergencyDashboardScreen(),
        AppRoutes.guardianNetwork: (_) => const GuardianNetworkScreen(),
        AppRoutes.riskAlert: (_) => const RiskAlertScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),
        AppRoutes.settings: (_) => const SettingsScreen(),
      },
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surface,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Poppins',
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}
