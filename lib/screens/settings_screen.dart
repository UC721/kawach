import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _shakeEnabled = true;
  bool _voiceEnabled = true;
  bool _motionEnabled = true;
  bool _offlineMode = true;
  bool _notificationsEnabled = true;
  double _shakeThreshold = 3.0; // 1–5 scale

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _shakeEnabled = prefs.getBool('shake_enabled') ?? true;
      _voiceEnabled = prefs.getBool('voice_enabled') ?? true;
      _motionEnabled = prefs.getBool('motion_enabled') ?? true;
      _offlineMode = prefs.getBool('offline_mode') ?? true;
      _notificationsEnabled = prefs.getBool('notif_enabled') ?? true;
      _shakeThreshold = prefs.getDouble('shake_threshold') ?? 3.0;
    });
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('shake_enabled', _shakeEnabled);
    await prefs.setBool('voice_enabled', _voiceEnabled);
    await prefs.setBool('motion_enabled', _motionEnabled);
    await prefs.setBool('offline_mode', _offlineMode);
    await prefs.setBool('notif_enabled', _notificationsEnabled);
    await prefs.setDouble('shake_threshold', _shakeThreshold);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader('Detection Settings'),
          _ToggleTile(
            icon: Icons.vibration,
            title: 'Shake Detection',
            subtitle: 'Shake phone 3x to trigger SOS',
            value: _shakeEnabled,
            onChanged: (v) {
              setState(() => _shakeEnabled = v);
              _savePrefs();
            },
          ),
          _ToggleTile(
            icon: Icons.mic_outlined,
            title: 'Voice Detection',
            subtitle: 'Detect panic phrases like "help me"',
            value: _voiceEnabled,
            onChanged: (v) {
              setState(() => _voiceEnabled = v);
              _savePrefs();
            },
          ),
          _ToggleTile(
            icon: Icons.screen_rotation_outlined,
            title: 'Motion Detection',
            subtitle: 'Detect phone snatching via accelerometer',
            value: _motionEnabled,
            onChanged: (v) {
              setState(() => _motionEnabled = v);
              _savePrefs();
            },
          ),
          const SizedBox(height: 8),
          // Shake sensitivity
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shake Sensitivity: ${_shakeThreshold.toStringAsFixed(1)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 13),
                ),
                Slider(
                  value: _shakeThreshold,
                  min: 1.0,
                  max: 5.0,
                  divisions: 8,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.surfaceVariant,
                  onChanged: (v) {
                    setState(() => _shakeThreshold = v);
                    _savePrefs();
                  },
                ),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Sensitive',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11)),
                    Text('Firm',
                        style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SectionHeader('Notifications'),
          _ToggleTile(
            icon: Icons.notifications_outlined,
            title: 'Push Notifications',
            subtitle: 'Receive emergency alerts',
            value: _notificationsEnabled,
            onChanged: (v) {
              setState(() => _notificationsEnabled = v);
              _savePrefs();
            },
          ),
          const SizedBox(height: 16),
          const _SectionHeader('Connectivity'),
          _ToggleTile(
            icon: Icons.wifi_off_outlined,
            title: 'Offline Emergency Mode',
            subtitle: 'Store and sync emergencies when offline',
            value: _offlineMode,
            onChanged: (v) {
              setState(() => _offlineMode = v);
              _savePrefs();
            },
          ),
          const SizedBox(height: 24),
          const _SectionHeader('About'),
          const _InfoTile(Icons.info_outline, 'App Version', '1.0.0'),
          const _InfoTile(Icons.security_outlined, 'Build', 'KAWACH Production'),
          const _InfoTile(
              Icons.shield_outlined, 'Data', 'End-to-end encrypted'),
          const SizedBox(height: 32),
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
      padding: const EdgeInsets.fromLTRB(4, 8, 0, 12),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1)),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14)),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoTile(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 14),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const Spacer(),
          Text(value,
              style:
                  const TextStyle(color: Colors.white54, fontSize: 13)),
        ],
      ),
    );
  }
}
