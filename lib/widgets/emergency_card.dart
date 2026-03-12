import 'package:flutter/material.dart';

import '../models/emergency_model.dart';
import '../utils/constants.dart';

/// Card showing active emergency status summary.
class EmergencyCard extends StatelessWidget {
  final EmergencyModel emergency;
  final VoidCallback? onTap;

  const EmergencyCard({
    super.key,
    required this.emergency,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.danger.withOpacity(0.4)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.danger.withOpacity(0.2),
              ),
              child: const Icon(Icons.warning_rounded,
                  color: AppColors.danger, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🚨 EMERGENCY ACTIVE',
                    style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Triggered by: ${emergency.triggeredBy.name.toUpperCase()}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    _formatTime(emergency.createdAt),
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.danger, size: 20),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m · ${dt.day}/${dt.month}/${dt.year}';
  }
}
