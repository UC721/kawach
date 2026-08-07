import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/incident_event_model.dart';
import '../services/incident_history_service.dart';
import '../services/user_service.dart';
import '../utils/constants.dart';

class IncidentHistoryScreen extends StatefulWidget {
  const IncidentHistoryScreen({super.key});

  @override
  State<IncidentHistoryScreen> createState() => _IncidentHistoryScreenState();
}

class _IncidentHistoryScreenState extends State<IncidentHistoryScreen> {
  final Set<IncidentKind> _filters = {
    for (final k in IncidentKind.values) k,
  };

  String _currentUserId() {
    final auth = Supabase.instance.client.auth.currentUser?.id;
    if (auth != null && auth.isNotEmpty) {
      return auth;
    }
    return context.read<UserService>().currentUserModel?.userId ?? '';
  }

  Future<void> _load() async {
    await context
        .read<IncidentHistoryService>()
        .buildTimeline(_currentUserId());
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<IncidentHistoryService>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Incident History')),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: service.loading
                ? const Center(child: CircularProgressIndicator())
                : service.events.isEmpty
                    ? const _EmptyState()
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _buildTimeline(service),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          for (final kind in IncidentKind.values) _filterChip(kind),
        ],
      ),
    );
  }

  Widget _filterChip(IncidentKind kind) {
    final active = _filters.contains(kind);
    final color = _colorFor(kind);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(_labelFor(kind)),
        selected: active,
        onSelected: (v) {
          setState(() {
            if (v) {
              _filters.add(kind);
            } else {
              _filters.remove(kind);
            }
          });
        },
        selectedColor: color.withValues(alpha: 0.15),
        checkmarkColor: color,
        labelStyle: TextStyle(
          color: active ? color : AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide(color: active ? color : Colors.grey.shade300),
      ),
    );
  }

  Widget _buildTimeline(IncidentHistoryService service) {
    final filtered =
        service.events.where((e) => _filters.contains(e.kind)).toList();
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final event = filtered[index];
        return _TimelineTile(event: event, isFirst: index == 0);
      },
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final IncidentEventModel event;
  final bool isFirst;
  const _TimelineTile({required this.event, required this.isFirst});

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(event.kind);
    final icon = _iconFor(event.kind);
    final when = DateFormat('MMM d, h:mm a').format(event.timestamp.toLocal());
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                            color: color.withValues(alpha: 0.4), blurRadius: 4),
                      ],
                    ),
                  ),
                ),
                if (!isFirst)
                  Expanded(
                    child: Container(width: 2, color: Colors.grey.shade200),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(event.title,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600)),
                        if (event.detail.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(event.detail,
                              style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12)),
                        ],
                        const SizedBox(height: 4),
                        Text(when,
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No incidents yet',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
          const SizedBox(height: 8),
          Text('Your SOS history and evidence will appear here.',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13)),
        ],
      ),
    );
  }
}

IconData _iconFor(IncidentKind kind) {
  switch (kind) {
    case IncidentKind.emergency:
      return Icons.sos;
    case IncidentKind.resolved:
      return Icons.check_circle_outline;
    case IncidentKind.evidence:
      return Icons.videocam_outlined;
    case IncidentKind.acknowledgement:
      return Icons.people_outline;
    case IncidentKind.activity:
      return Icons.event_note_outlined;
  }
}

Color _colorFor(IncidentKind kind) {
  switch (kind) {
    case IncidentKind.emergency:
      return AppColors.danger;
    case IncidentKind.resolved:
      return const Color(0xFF00C853);
    case IncidentKind.evidence:
      return const Color(0xFF2979FF);
    case IncidentKind.acknowledgement:
      return const Color(0xFF7C4DFF);
    case IncidentKind.activity:
      return const Color(0xFFFF6F61);
  }
}

String _labelFor(IncidentKind kind) {
  switch (kind) {
    case IncidentKind.emergency:
      return 'SOS';
    case IncidentKind.resolved:
      return 'Resolved';
    case IncidentKind.evidence:
      return 'Evidence';
    case IncidentKind.acknowledgement:
      return 'Guardian';
    case IncidentKind.activity:
      return 'Activity';
  }
}
