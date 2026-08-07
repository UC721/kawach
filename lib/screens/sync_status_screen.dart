import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/offline_emergency_service.dart';
import '../services/sos_queue_manager.dart';
import '../utils/constants.dart';

class SyncStatusScreen extends StatefulWidget {
  const SyncStatusScreen({super.key});

  @override
  State<SyncStatusScreen> createState() => _SyncStatusScreenState();
}

class _SyncStatusScreenState extends State<SyncStatusScreen> {
  int _pending = 0;

  @override
  void initState() {
    super.initState();
    context.read<OfflineEmergencyService>().restoreSyncState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshPending());
  }

  Future<void> _refreshPending() async {
    final count = await SosQueueManager.instance.snapshot();
    if (!mounted) return;
    setState(() {
      _pending = count.emergencies +
          count.locations +
          count.evidence +
          count.meshPackets;
    });
  }

  Future<void> _syncNow() async {
    await context.read<OfflineEmergencyService>().syncPendingEmergencies();
    await _refreshPending();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<OfflineEmergencyService>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Sync Status')),
      body: RefreshIndicator(
        onRefresh: _syncNow,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _buildStatusCard(service),
            const SizedBox(height: 20),
            const _SectionHeader('QUEUE'),
            Row(
              children: [
                Expanded(
                  child: _QueueCard(
                      icon: Icons.sos, label: 'SOS', count: _pending),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('$_pending item(s) waiting to sync to the server.',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 20),
            const _SectionHeader('LAST SYNC RESULTS'),
            ..._buildResults(service),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: service.isSyncing ? null : _syncNow,
            icon: service.isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            label: Text(service.isSyncing ? 'Syncing…' : 'Sync now'),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(OfflineEmergencyService service) {
    final healthy = service.hasSyncedOnce || _pending == 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (healthy ? const Color(0xFF00C853) : const Color(0xFFFF6D00))
            .withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: (healthy ? const Color(0xFF00C853) : const Color(0xFFFF6D00))
                .withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(healthy ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              color:
                  healthy ? const Color(0xFF00C853) : const Color(0xFFFF6D00),
              size: 32),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    service.lastSyncedAt == null
                        ? 'Not synced yet'
                        : 'Last synced '
                            '${DateFormat('MMM d, h:mm a').format(service.lastSyncedAt!.toLocal())}',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                    service.isSyncing
                        ? 'Syncing now…'
                        : healthy
                            ? 'Everything is in sync. Offline events reconcile '
                                'on reconnection.'
                            : 'There are pending offline events.',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildResults(OfflineEmergencyService service) {
    if (service.lastResults.isEmpty) {
      return const [
        _EmptyHint(
            text:
                'No sync has run yet. Tap “Sync now” to upload pending data.'),
      ];
    }
    return [
      for (final result in service.lastResults) _ResultTile(result: result),
    ];
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 0, 10),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2)),
    );
  }
}

class _QueueCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  const _QueueCard(
      {required this.icon, required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
          Text('$count',
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final SyncBucketResult result;
  const _ResultTile({required this.result});

  @override
  Widget build(BuildContext context) {
    final color = result.failed > 0
        ? AppColors.danger
        : result.succeeded > 0
            ? const Color(0xFF00C853)
            : AppColors.textSecondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(
              result.failed > 0
                  ? Icons.error_outline
                  : Icons.check_circle_outline,
              color: color,
              size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(result.bucket.toUpperCase(),
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
                Text(
                  [
                    if (result.attempted > 0) '${result.attempted} attempted',
                    if (result.succeeded > 0) '${result.succeeded} synced',
                    if (result.failed > 0) '${result.failed} failed',
                    if (result.resolvedConflicts > 0)
                      '${result.resolvedConflicts} conflicts resolved',
                    if (result.skippedDuplicates > 0)
                      '${result.skippedDuplicates} duplicates dropped',
                    if (result.attempted == 0) 'nothing to do',
                  ].join(' · '),
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style: const TextStyle(
              color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
    );
  }
}
