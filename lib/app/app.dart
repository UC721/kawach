import 'package:flutter/material.dart';
import 'package:kawach/app/router.dart';
import 'package:kawach/core/constants/app_constants.dart';

/// MaterialApp wrapper with GoRouter-based navigation.
class KawachCleanApp extends StatelessWidget {
  const KawachCleanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      routerConfig: appRouter,
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFE53935),
        secondary: Color(0xFFFF6F61),
        surface: Color(0xFF1A1A2E),
        error: Color(0xFFFF1744),
      ),
      scaffoldBackgroundColor: const Color(0xFF0D0D0D),
      fontFamily: 'Poppins',
    );
  }
}
