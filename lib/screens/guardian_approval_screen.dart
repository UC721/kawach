import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/emergency_model.dart';
import '../models/guardian_request_model.dart';
import '../models/sos_acknowledgement_model.dart';
import '../services/guardian_lifecycle_service.dart';
import '../services/user_service.dart';
import '../utils/constants.dart';

class GuardianApprovalScreen extends StatefulWidget {
  const GuardianApprovalScreen({super.key});

  @override
  State<GuardianApprovalScreen> createState() => _GuardianApprovalScreenState();
}

class _GuardianApprovalScreenState extends State<GuardianApprovalScreen> {
  String _guardianId = '';

  @override
  void initState() {
    super.initState();
    _guardianId = _currentUserId();
    final lifecycle = context.read<GuardianLifecycleService>();
    lifecycle.listenIncoming(_guardianId);
    lifecycle.listenGuardingEmergencies(_guardianId);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GuardianLifecycleService>().fetchOutgoing(_guardianId);
    });
  }

  String _currentUserId() {
    final auth = Supabase.instance.client.auth.currentUser?.id;
    if (auth != null && auth.isNotEmpty) {
      return auth;
    }
    return context.read<UserService>().currentUserModel?.userId ?? '';
  }

  String _guardianName() {
    return context.read<UserService>().currentUserModel?.name ?? 'Me';
  }

  @override
  Widget build(BuildContext context) {
    final lifecycle = context.watch<GuardianLifecycleService>();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Guardian Feedback Loop'),
          bottom: const TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: 'Requests'),
              Tab(text: 'SOS Response'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildRequests(lifecycle),
            _buildResponse(lifecycle),
          ],
        ),
      ),
    );
  }

  Widget _buildRequests(GuardianLifecycleService lifecycle) {
    return StreamBuilder<List<GuardianRequestModel>>(
      stream: lifecycle.incomingRequests,
      builder: (context, snap) {
        final incoming = snap.data ?? const <GuardianRequestModel>[];
        return RefreshIndicator(
          onRefresh: () => lifecycle.fetchOutgoing(_guardianId),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const _SectionHeader('Incoming guardian requests'),
              if (incoming.isEmpty)
                const _EmptyHint(
                  icon: Icons.mark_email_unread_outlined,
                  text: 'No pending requests. When someone asks you to guard '
                      'them, approve or decline here.',
                )
              else
                for (final request in incoming)
                  _IncomingRequestCard(
                    request: request,
                    onAccept: () => lifecycle.respondToRequest(
                        request: request, accept: true),
                    onDecline: () => lifecycle.respondToRequest(
                        request: request, accept: false),
                  ),
              const SizedBox(height: 16),
              const _SectionHeader('Sent by you'),
              if (lifecycle.outgoingRequests.isEmpty)
                const _EmptyHint(
                  icon: Icons.send_outlined,
                  text: 'Add a guardian in Guardian Network to send a request.',
                )
              else
                for (final request in lifecycle.outgoingRequests)
                  _OutgoingRequestTile(request),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResponse(GuardianLifecycleService lifecycle) {
    return StreamBuilder<List<EmergencyModel>>(
      stream: lifecycle.guardingEmergencies,
      builder: (context, snap) {
        final emergencies = snap.data ?? const <EmergencyModel>[];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _InfoBanner(
              icon: Icons.people_outline,
              text:
                  'These are SOS events from people who guard you. Reply so they '
                  'know you are responding, or that you have confirmed they are safe.',
            ),
            const SizedBox(height: 12),
            if (emergencies.isEmpty)
              const _EmptyHint(
                icon: Icons.shield_outlined,
                text: 'No live SOS from your guarded circle right now.',
              )
            else
              for (final emergency in emergencies)
                _EmergencyResponseCard(
                  emergency: emergency,
                  onAck: (status) => lifecycle.acknowledgeSos(
                    emergencyId: emergency.emergencyId,
                    emergencyUserId: emergency.userId,
                    guardianUserId: _guardianId,
                    guardianName: _guardianName(),
                    status: status,
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _IncomingRequestCard extends StatelessWidget {
  final GuardianRequestModel request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const _IncomingRequestCard({
    required this.request,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(request.initiatorName.isNotEmpty
                    ? request.initiatorName[0].toUpperCase()
                    : '?'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${request.initiatorName} wants you to be a guardian',
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    Text(request.initiatorPhone,
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onAccept,
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OutgoingRequestTile extends StatelessWidget {
  final GuardianRequestModel request;
  const _OutgoingRequestTile(this.request);

  @override
  Widget build(BuildContext context) {
    final isPending = request.status == GuardianRequestStatus.pending;
    final color = isPending
        ? const Color(0xFFFF6D00)
        : request.status == GuardianRequestStatus.accepted
            ? const Color(0xFF00C853)
            : const Color(0xFF9E9E9E);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.person_outline, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(request.initiatorPhone,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 14)),
                Text(_statusLabel(request.status),
                    style: TextStyle(color: color, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _statusLabel(GuardianRequestStatus s) {
  switch (s) {
    case GuardianRequestStatus.pending:
      return 'Request pending';
    case GuardianRequestStatus.accepted:
      return 'Guardian accepted';
    case GuardianRequestStatus.declined:
      return 'Guardian declined';
  }
}

class _EmergencyResponseCard extends StatelessWidget {
  final EmergencyModel emergency;
  final ValueChanged<SosAckStatus> onAck;
  const _EmergencyResponseCard({required this.emergency, required this.onAck});

  @override
  Widget build(BuildContext context) {
    final when =
        DateFormat('MMM d, h:mm a').format(emergency.createdAt.toLocal());
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.sos, color: AppColors.danger),
              SizedBox(width: 8),
              Text('SOS ACTIVE',
                  style: TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Triggered by ${emergency.triggeredBy.name} at $when',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => onAck(SosAckStatus.checking),
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Checking'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => onAck(SosAckStatus.confirmedSafe),
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('They are Safe'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoBanner({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
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

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 0, 8),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1)),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String text;
  const _EmptyHint({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(icon, size: 44, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
        ],
      ),
    );
  }
}
