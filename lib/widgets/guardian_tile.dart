import 'package:flutter/material.dart';

import '../models/guardian_network_model.dart';
import '../utils/constants.dart';

/// Guardian network volunteer tile with verification badge and availability.
class GuardianTile extends StatelessWidget {
  final GuardianNetworkModel volunteer;

  const GuardianTile({super.key, required this.volunteer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          // Avatar + online indicator
          Stack(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: AppColors.safe.withOpacity(0.15),
                child: Text(
                  volunteer.name.isNotEmpty
                      ? volunteer.name[0].toUpperCase()
                      : 'V',
                  style: const TextStyle(
                      color: AppColors.safe, fontWeight: FontWeight.w700),
                ),
              ),
              if (volunteer.availability)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 11,
                    height: 11,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.safe,
                      border: Border.all(
                          color: AppColors.surface, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(volunteer.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    if (volunteer.verified) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified_rounded,
                          color: AppColors.primary, size: 15),
                    ],
                  ],
                ),
                Text(
                  volunteer.availability
                      ? '🟢 Available'
                      : '🔴 Unavailable',
                  style: TextStyle(
                      color: volunteer.availability
                          ? AppColors.safe
                          : AppColors.textSecondary,
                      fontSize: 11),
                ),
              ],
            ),
          ),
          // Volunteer badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.safe.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.safe.withOpacity(0.3)),
            ),
            child: const Text('Volunteer',
                style: TextStyle(color: AppColors.safe, fontSize: 10)),
          ),
        ],
      ),
    );
  }
}
