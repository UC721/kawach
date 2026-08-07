import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/nearby_alert_model.dart';
import '../screens/guardian_monitor_screen.dart';
import '../services/guardian_network_service.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';
import '../widgets/guardian_tile.dart';

class GuardianNetworkScreen extends StatefulWidget {
  const GuardianNetworkScreen({super.key});

  @override
  State<GuardianNetworkScreen> createState() => _GuardianNetworkScreenState();
}

class _GuardianNetworkScreenState extends State<GuardianNetworkScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  bool _isJoining = false;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadNearby();
  }

  Future<void> _loadNearby() async {
    try {
      final locationService = context.read<LocationService>();
      final guardianService = context.read<GuardianNetworkService>();
      final pos = await locationService.getCurrentPosition();
      await guardianService.findNearbyVolunteers(
          lat: pos.latitude, lng: pos.longitude);
    } catch (_) {}
  }

  Future<void> _joinNetwork() async {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) return;
    setState(() => _isJoining = true);
    try {
      final locationService = context.read<LocationService>();
      final guardianService = context.read<GuardianNetworkService>();
      final pos = await locationService.getCurrentPosition();
      await guardianService.registerAsVolunteer(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          lat: pos.latitude,
          lng: pos.longitude);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Registered! Pending verification.'),
              backgroundColor: Colors.green),
        );
        _tabs.animateTo(0);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<GuardianNetworkService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Guardian Network'),
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          tabs: const [
            Tab(text: 'Nearby Volunteers'),
            Tab(text: 'Join Network'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          // Nearby volunteers
          StreamBuilder<List<NearbyAlertModel>>(
            stream: service.streamIncomingAlerts(),
            builder: (_, alertSnap) {
              final alerts = alertSnap.data ?? const [];
              if (service.nearbyVolunteers.isEmpty && alerts.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline,
                          size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      const Text('No volunteers or live SOS nearby',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 16)),
                      const SizedBox(height: 8),
                      TextButton(
                          onPressed: _loadNearby, child: const Text('Refresh')),
                    ],
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (alerts.isNotEmpty) ...[
                    const Text(
                      'Nearby SOS Alerts',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...alerts.map((alert) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _IncomingAlertCard(alert: alert),
                        )),
                    const SizedBox(height: 12),
                  ],
                  if (service.nearbyVolunteers.isNotEmpty) ...[
                    const Text(
                      'Nearby Volunteers',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...service.nearbyVolunteers.map((volunteer) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: GuardianTile(volunteer: volunteer),
                        )),
                  ],
                ],
              );
            },
          ),
          // Join network
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.safe.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.safe.withValues(alpha: 0.3)),
                  ),
                  child: const Text(
                    'Join as a volunteer to receive emergency alerts from users near you. '
                    'Your account will be verified before you are visible to others.',
                    style:
                        TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 24),
                _buildField(_nameCtrl, 'Your Name', Icons.person_outline),
                const SizedBox(height: 16),
                _buildField(_phoneCtrl, 'Phone Number', Icons.phone_outlined,
                    type: TextInputType.phone),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isJoining ? null : _joinNetwork,
                    icon: _isJoining
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.volunteer_activism),
                    label: const Text('Join Guardian Network'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
    );
  }
}

class _IncomingAlertCard extends StatelessWidget {
  const _IncomingAlertCard({required this.alert});

  final NearbyAlertModel alert;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GuardianMonitorScreen(
              watchedUserId: alert.userId,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.danger.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            const Icon(Icons.sos, color: AppColors.danger, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.userName ?? 'Nearby user needs help',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to open live tracking for this SOS',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
