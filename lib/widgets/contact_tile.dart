import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/guardian_model.dart';
import '../utils/constants.dart';

/// Contact tile for emergency contact list – shows name, relation, call/SMS.
class ContactTile extends StatelessWidget {
  final GuardianModel guardian;
  final VoidCallback? onDelete;

  const ContactTile({
    super.key,
    required this.guardian,
    this.onDelete,
  });

  Future<void> _call() async {
    final uri = Uri.parse('tel:${guardian.phone}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _sms() async {
    final uri = Uri.parse('sms:${guardian.phone}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            child: Text(
              guardian.name.isNotEmpty
                  ? guardian.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(guardian.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                Text(
                  '${guardian.relationship} · ${guardian.phone}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.call_outlined,
                color: AppColors.safe, size: 20),
            onPressed: _call,
          ),
          IconButton(
            icon: const Icon(Icons.sms_outlined,
                color: AppColors.secondary, size: 20),
            onPressed: _sms,
          ),
          if (onDelete != null)
            IconButton(
              icon: const Icon(Icons.delete_outline,
                  color: AppColors.textSecondary, size: 18),
              onPressed: onDelete,
            ),
        ],
      ),
    );
  }
}
