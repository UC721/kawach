import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/privacy_service.dart';
import '../services/user_service.dart';
import '../utils/constants.dart';

class PrivacyConsoleScreen extends StatefulWidget {
  const PrivacyConsoleScreen({super.key});

  @override
  State<PrivacyConsoleScreen> createState() => _PrivacyConsoleScreenState();
}

class _PrivacyConsoleScreenState extends State<PrivacyConsoleScreen> {
  String _currentUserId() {
    final auth = Supabase.instance.client.auth.currentUser?.id;
    if (auth != null && auth.isNotEmpty) {
      return auth;
    }
    return context.read<UserService>().currentUserModel?.userId ?? '';
  }

  @override
  void initState() {
    super.initState();
    context.read<PrivacyService>().ensureLocalKey();
  }

  Future<void> _export() async {
    final service = context.read<PrivacyService>();
    final export = await service.exportData(_currentUserId());
    if (!mounted) return;
    final summary =
        export.counts.entries.map((e) => '${e.key}: ${e.value}').join('\n');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your data export is ready'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                summary,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 12),
              const Text(
                'The full JSON export has been copied to your clipboard.',
                style: TextStyle(
                    color: AppColors.textPrimary, fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
    await Clipboard.setData(ClipboardData(text: export.json));
  }

  Future<void> _rotateKey() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rotate local encryption key?'),
        content: const Text(
          'A new key is generated for this device only. Any data that was '
          'encrypted with the old key on other devices is unaffected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rotate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final service = context.read<PrivacyService>();
    final fingerprint = await service.rotateLocalKey();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('New key fingerprint: $fingerprint'),
        backgroundColor: const Color(0xFF00C853),
      ),
    );
  }

  Future<void> _erase() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Erase all KAWACH data?'),
        content: const Text(
          'This permanently deletes your guardians, emergencies, evidence '
          'metadata, reports and profiles from the servers, and clears all '
          'local data. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Erase everything'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!mounted) return;
    final service = context.read<PrivacyService>();
    final userId = _currentUserId();
    await service.eraseAllData(userId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Your data has been erased.'),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<PrivacyService>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Privacy & Data')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader('EXPORT'),
          _ActionCard(
            icon: Icons.file_download_outlined,
            title: 'Export my data',
            subtitle:
                'Download a JSON copy of everything KAWACH stores about you',
            color: const Color(0xFF2979FF),
            loading: service.exporting,
            onTap: _export,
          ),
          const SizedBox(height: 16),
          const _SectionHeader('LOCAL ENCRYPTION'),
          _FingerprintCard(
            fingerprint: service.localKeyFingerprint ?? 'Loading…',
            onRotate: _rotateKey,
          ),
          const SizedBox(height: 16),
          const _SectionHeader('DATA ERASURE'),
          _ActionCard(
            icon: Icons.delete_forever_outlined,
            title: 'Erase my data',
            subtitle:
                'Remove your profile, guardians, history and local storage',
            color: AppColors.danger,
            loading: service.erasing,
            destructive: true,
            onTap: _erase,
          ),
          const SizedBox(height: 16),
          const _SectionHeader('PRIVACY NOTES'),
          const _Note(
            icon: Icons.shield_outlined,
            text: 'Emergency data is stored end-to-end encrypted in transit. '
                'Your mesh packets use per-packet nonces and MACs.',
          ),
          const _Note(
            icon: Icons.info_outline,
            text:
                'Export gives you a portable copy. Use it to switch providers '
                'or keep a personal backup.',
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 0, 10),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2)),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool loading;
  final bool destructive;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.loading,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: color,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                          height: 1.3)),
                ],
              ),
            ),
            if (loading)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            else
              Icon(Icons.arrow_forward_ios,
                  size: 14, color: color.withValues(alpha: 0.6)),
          ],
        ),
      ),
    );
  }
}

class _FingerprintCard extends StatelessWidget {
  final String fingerprint;
  final VoidCallback onRotate;

  const _FingerprintCard({required this.fingerprint, required this.onRotate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.key, color: AppColors.textSecondary, size: 20),
              SizedBox(width: 8),
              Text('Local key fingerprint',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(10),
            ),
            child: SelectableText(
              fingerprint,
              style: const TextStyle(
                  fontFamily: 'monospace', fontSize: 14, letterSpacing: 1.5),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Use this to verify data was encrypted on this device. Rotating '
            'generates a fresh key.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: OutlinedButton.icon(
              onPressed: onRotate,
              icon: const Icon(Icons.autorenew, size: 18),
              label: const Text('Rotate key'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Note({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
