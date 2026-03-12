import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/emergency_service.dart';
import '../utils/constants.dart';

/// Full-screen stealth mode – plain black screen.
/// Emergency continues running silently in the background.
class StealthModeScreen extends StatelessWidget {
  const StealthModeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        // Triple-tap to exit stealth mode
        onDoubleTap: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: AppColors.surface,
              title: const Text('Exit Stealth Mode?',
                  style: TextStyle(color: Colors.white)),
              content: const Text(
                'Emergency will continue running. Enter your PIN to exit.',
                style: TextStyle(color: Colors.white70),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Stay Hidden',
                      style: TextStyle(color: Colors.grey)),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context
                        .read<EmergencyService>()
                        .deactivateStealthMode();
                    Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRoutes.emergencyDashboard,
                        (_) => false);
                  },
                  child: const Text('Exit',
                      style: TextStyle(color: AppColors.danger)),
                ),
              ],
            ),
          );
        },
        child: const SizedBox.expand(child: ColoredBox(color: Colors.black)),
      ),
    );
  }
}
