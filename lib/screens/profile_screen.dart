import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../models/guardian_model.dart';
import '../utils/constants.dart';
import '../widgets/contact_tile.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _gNameCtrl = TextEditingController();
  final _gPhoneCtrl = TextEditingController();
  final _gRelCtrl = TextEditingController();
  bool _editMode = false;
  List<GuardianModel> _guardians = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await context.read<UserService>().loadCurrentUser(uid);
    final user = context.read<UserService>().currentUserModel;
    if (user != null) {
      _nameCtrl.text = user.name;
      _phoneCtrl.text = user.phone;
      _guardians = await context.read<UserService>().getGuardians(uid);
      setState(() {});
    }
  }

  Future<void> _saveProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await context.read<UserService>().updateUser(uid, {
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
    });
    setState(() => _editMode = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Profile updated')));
    }
  }

  Future<void> _addGuardian() async {
    if (_gNameCtrl.text.isEmpty || _gPhoneCtrl.text.isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final guardian = GuardianModel(
      guardianId: '',
      userId: uid,
      name: _gNameCtrl.text.trim(),
      phone: _gPhoneCtrl.text.trim(),
      relationship: _gRelCtrl.text.trim().isEmpty
          ? 'Contact'
          : _gRelCtrl.text.trim(),
    );
    await context.read<UserService>().addGuardian(guardian);
    _gNameCtrl.clear();
    _gPhoneCtrl.clear();
    _gRelCtrl.clear();
    await _loadData();
    if (mounted) Navigator.pop(context);
  }

  void _showAddGuardian() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Emergency Contact',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            _Field(_gNameCtrl, 'Full Name', Icons.person_outline),
            const SizedBox(height: 12),
            _Field(_gPhoneCtrl, 'Phone Number', Icons.phone_outlined,
                type: TextInputType.phone),
            const SizedBox(height: 12),
            _Field(_gRelCtrl, 'Relationship (e.g. Mom)',
                Icons.favorite_outline),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                  onPressed: _addGuardian,
                  child: const Text('Add Contact')),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserService>().currentUserModel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          TextButton(
            onPressed: () {
              if (_editMode) {
                _saveProfile();
              } else {
                setState(() => _editMode = true);
              }
            },
            child: Text(_editMode ? 'Save' : 'Edit',
                style: const TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar
          Center(
            child: CircleAvatar(
              radius: 44,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: Text(
                (user?.name.isNotEmpty == true
                        ? user!.name[0]
                        : 'U')
                    .toUpperCase(),
                style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 36,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Profile fields
          _Field(_nameCtrl, 'Full Name', Icons.person_outline,
              enabled: _editMode),
          const SizedBox(height: 12),
          _Field(_phoneCtrl, 'Phone Number', Icons.phone_outlined,
              enabled: _editMode, type: TextInputType.phone),
          const SizedBox(height: 8),
          if (user?.email != null)
            _ReadOnly('Email', user!.email!, Icons.email_outlined),
          const SizedBox(height: 28),
          // Emergency contacts
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Emergency Contacts',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: AppColors.primary),
                  onPressed: _showAddGuardian),
            ],
          ),
          const SizedBox(height: 8),
          if (_guardians.isEmpty)
            _EmptyGuardians(onAdd: _showAddGuardian)
          else
            ..._guardians.map((g) => ContactTile(
                  guardian: g,
                  onDelete: () async {
                    final uid =
                        FirebaseAuth.instance.currentUser?.uid ?? '';
                    await context
                        .read<UserService>()
                        .removeGuardian(uid, g.guardianId);
                    await _loadData();
                  },
                )),
          const SizedBox(height: 32),
          // Sign out
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: AppColors.danger.withOpacity(0.6)),
              foregroundColor: AppColors.danger,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Sign Out'),
            onPressed: () async {
              await context.read<AuthService>().signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.login, (_) => false);
              }
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final IconData icon;
  final bool enabled;
  final TextInputType type;

  const _Field(this.ctrl, this.label, this.icon,
      {this.enabled = true, this.type = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      enabled: enabled,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
          labelText: label,
          prefixIcon:
              Icon(icon, color: AppColors.textSecondary, size: 20)),
    );
  }
}

class _ReadOnly extends StatelessWidget {
  final String label, value;
  final IconData icon;
  const _ReadOnly(this.label, this.value, this.icon);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 11)),
            Text(value,
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ]),
        ],
      ),
    );
  }
}

class _EmptyGuardians extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyGuardians({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppColors.cardBorder,
              style: BorderStyle.solid),
        ),
        child: const Column(
          children: [
            Icon(Icons.person_add_outlined,
                size: 36, color: AppColors.textSecondary),
            SizedBox(height: 8),
            Text('Add Emergency Contacts',
                style: TextStyle(
                    color: AppColors.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
