import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/guardian_network_service.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';
import '../widgets/guardian_tile.dart';

class GuardianNetworkScreen extends StatefulWidget {
  const GuardianNetworkScreen({super.key});

  @override
  State<GuardianNetworkScreen> createState() =>
      _GuardianNetworkScreenState();
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
      final pos =
          await context.read<LocationService>().getCurrentPosition();
      await context.read<GuardianNetworkService>().findNearbyVolunteers(
          lat: pos.latitude, lng: pos.longitude);
    } catch (_) {}
  }

  Future<void> _joinNetwork() async {
    if (_nameCtrl.text.isEmpty || _phoneCtrl.text.isEmpty) return;
    setState(() => _isJoining = true);
    try {
      final pos =
          await context.read<LocationService>().getCurrentPosition();
      await context.read<GuardianNetworkService>().registerAsVolunteer(
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
              content: Text('Error: $e'),
              backgroundColor: AppColors.danger),
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
          labelColor: Colors.white,
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
          service.nearbyVolunteers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.people_outline,
                          size: 64, color: AppColors.textSecondary),
                      const SizedBox(height: 16),
                      const Text('No volunteers nearby',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 16)),
                      const SizedBox(height: 8),
                      TextButton(
                          onPressed: _loadNearby,
                          child: const Text('Refresh')),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: service.nearbyVolunteers.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (_, i) => GuardianTile(
                      volunteer: service.nearbyVolunteers[i]),
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
                    color: AppColors.safe.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppColors.safe.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'Join as a volunteer to receive emergency alerts from users near you. '
                    'Your account will be verified before you are visible to others.',
                    style:
                        TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ),
                const SizedBox(height: 24),
                _buildField(_nameCtrl, 'Your Name', Icons.person_outline),
                const SizedBox(height: 16),
                _buildField(_phoneCtrl, 'Phone Number',
                    Icons.phone_outlined,
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
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            Icon(icon, color: AppColors.textSecondary, size: 20),
      ),
    );
  }
}
