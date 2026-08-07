import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/emergency_profile_model.dart';
import '../services/emergency_profile_service.dart';
import '../services/user_service.dart';
import '../utils/constants.dart';

class EmergencyProfileScreen extends StatefulWidget {
  const EmergencyProfileScreen({super.key});

  @override
  State<EmergencyProfileScreen> createState() => _EmergencyProfileScreenState();
}

class _EmergencyProfileScreenState extends State<EmergencyProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _doctorPhone;
  late TextEditingController _hospital;
  late TextEditingController _instructions;
  late TextEditingController _insuranceProvider;
  late TextEditingController _insurancePolicy;
  late TextEditingController _legalHolder;
  late TextEditingController _legalHolderPhone;
  late TextEditingController _allergyCtrl;
  late TextEditingController _medicationCtrl;
  late TextEditingController _conditionCtrl;

  String _bloodType = 'Unknown';
  bool _organDonor = false;
  final List<String> _allergies = [];
  final List<String> _medications = [];
  final List<String> _conditions = [];
  final List<EmergencyContact> _contacts = [];
  bool _saving = false;

  static const _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
    'Unknown',
  ];

  @override
  void initState() {
    super.initState();
    final ctrls = _makeControllers();
    _doctorPhone = ctrls[0];
    _hospital = ctrls[1];
    _instructions = ctrls[2];
    _insuranceProvider = ctrls[3];
    _insurancePolicy = ctrls[4];
    _legalHolder = ctrls[5];
    _legalHolderPhone = ctrls[6];
    _allergyCtrl = TextEditingController();
    _medicationCtrl = TextEditingController();
    _conditionCtrl = TextEditingController();
    _loadProfile();
  }

  List<TextEditingController> _makeControllers() {
    return List.generate(7, (_) => TextEditingController());
  }

  Future<void> _loadProfile() async {
    final userId = _currentUserId();
    await context.read<EmergencyProfileService>().load(userId);
    if (!mounted) return;
    final profile = context.read<EmergencyProfileService>().profile;
    setState(() {
      _bloodType = profile.bloodType;
      _organDonor = profile.organDonor;
      _allergies
        ..clear()
        ..addAll(profile.allergies);
      _medications
        ..clear()
        ..addAll(profile.medications);
      _conditions
        ..clear()
        ..addAll(profile.conditions);
      _contacts
        ..clear()
        ..addAll(profile.emergencyContacts);
      _doctorPhone.text = profile.doctorPhone ?? '';
      _hospital.text = profile.hospitalPreference ?? '';
      _instructions.text = profile.specialInstructions ?? '';
      _insuranceProvider.text = profile.insuranceProvider ?? '';
      _insurancePolicy.text = profile.insurancePolicyNo ?? '';
      _legalHolder.text = profile.legalHolder ?? '';
      _legalHolderPhone.text = profile.legalHolderPhone ?? '';
    });
  }

  String _currentUserId() {
    final fromAuth = Supabase.instance.client.auth.currentUser?.id;
    if (fromAuth != null && fromAuth.isNotEmpty) {
      return fromAuth;
    }
    return context.read<UserService>().currentUserModel?.userId ?? '';
  }

  @override
  void dispose() {
    _doctorPhone.dispose();
    _hospital.dispose();
    _instructions.dispose();
    _insuranceProvider.dispose();
    _insurancePolicy.dispose();
    _legalHolder.dispose();
    _legalHolderPhone.dispose();
    _allergyCtrl.dispose();
    _medicationCtrl.dispose();
    _conditionCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _saving = true);
    final uid = _currentUserId();
    final profile = EmergencyProfileModel(
      bloodType: _bloodType,
      allergies: List.from(_allergies),
      medications: List.from(_medications),
      conditions: List.from(_conditions),
      doctorPhone:
          _doctorPhone.text.trim().isEmpty ? null : _doctorPhone.text.trim(),
      hospitalPreference:
          _hospital.text.trim().isEmpty ? null : _hospital.text.trim(),
      specialInstructions:
          _instructions.text.trim().isEmpty ? null : _instructions.text.trim(),
      insuranceProvider: _insuranceProvider.text.trim().isEmpty
          ? null
          : _insuranceProvider.text.trim(),
      insurancePolicyNo: _insurancePolicy.text.trim().isEmpty
          ? null
          : _insurancePolicy.text.trim(),
      legalHolder:
          _legalHolder.text.trim().isEmpty ? null : _legalHolder.text.trim(),
      legalHolderPhone: _legalHolderPhone.text.trim().isEmpty
          ? null
          : _legalHolderPhone.text.trim(),
      organDonor: _organDonor,
      emergencyContacts: List.from(_contacts),
    );
    await context.read<EmergencyProfileService>().save(uid, profile);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency profile saved'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _addChip(
    List<String> list,
    TextEditingController ctrl,
  ) async {
    final value = ctrl.text.trim();
    if (value.isEmpty) return;
    setState(() => list.add(value));
    ctrl.clear();
  }

  Future<void> _addContact() async {
    final name = TextEditingController();
    final phone = TextEditingController();
    final relationship = TextEditingController();
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: phone,
              decoration: const InputDecoration(labelText: 'Phone'),
              keyboardType: TextInputType.phone,
            ),
            TextField(
              controller: relationship,
              decoration: const InputDecoration(labelText: 'Relationship'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (added == true && name.text.trim().isNotEmpty) {
      setState(() {
        _contacts.add(EmergencyContact(
          name: name.text.trim(),
          phone: phone.text.trim(),
          relationship: relationship.text.trim(),
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Emergency Profile')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const _InfoBanner(
              icon: Icons.local_hospital_outlined,
              text:
                  'This profile is shown to responders and guardians when SOS '
                  'is active. Keep it accurate and up to date.',
            ),
            const SizedBox(height: 12),
            const _SectionHeader('Medical'),
            _DropdownTile(
              icon: Icons.bloodtype_outlined,
              label: 'Blood Type',
              value: _bloodType,
              options: _bloodTypes,
              onChanged: (v) => setState(() => _bloodType = v),
            ),
            _TextButtonRow(
              icon: Icons.coronavirus_outlined,
              hint: 'Add allergy',
              controller: _allergyCtrl,
              label: 'Allergies',
              chips: _allergies,
              onAdd: () => _addChip(_allergies, _allergyCtrl),
              onRemove: (v) => setState(() => _allergies.remove(v)),
            ),
            _TextButtonRow(
              icon: Icons.medication_outlined,
              hint: 'Add medication',
              controller: _medicationCtrl,
              label: 'Medications',
              chips: _medications,
              onAdd: () => _addChip(_medications, _medicationCtrl),
              onRemove: (v) => setState(() => _medications.remove(v)),
            ),
            _TextButtonRow(
              icon: Icons.monitor_heart_outlined,
              hint: 'Add condition (e.g. asthma)',
              controller: _conditionCtrl,
              label: 'Conditions',
              chips: _conditions,
              onAdd: () => _addChip(_conditions, _conditionCtrl),
              onRemove: (v) => setState(() => _conditions.remove(v)),
            ),
            _TextField(
              controller: _doctorPhone,
              icon: Icons.person_pin_outlined,
              label: 'Doctor / Helpline Phone',
              keyboardType: TextInputType.phone,
            ),
            _TextField(
              controller: _hospital,
              icon: Icons.local_hospital_outlined,
              label: 'Preferred Hospital',
            ),
            const SizedBox(height: 16),
            const _SectionHeader('Insurance'),
            _TextField(
              controller: _insuranceProvider,
              icon: Icons.verified_user_outlined,
              label: 'Insurance Provider',
            ),
            _TextField(
              controller: _insurancePolicy,
              icon: Icons.badge_outlined,
              label: 'Policy Number',
            ),
            const SizedBox(height: 16),
            const _SectionHeader('Legal'),
            _TextField(
              controller: _legalHolder,
              icon: Icons.balance_outlined,
              label: 'Legal / Next of kin holder',
            ),
            _TextField(
              controller: _legalHolderPhone,
              icon: Icons.phone_outlined,
              label: 'Legal Holder Phone',
              keyboardType: TextInputType.phone,
            ),
            _SwitchTile(
              icon: Icons.favorite_outline,
              title: 'Organ Donor',
              subtitle: 'Declare your organ donation preference',
              value: _organDonor,
              onChanged: (v) => setState(() => _organDonor = v),
            ),
            const SizedBox(height: 16),
            const _SectionHeader('Emergency Contacts'),
            for (final contact in _contacts)
              _ContactTile(
                contact: contact,
                onRemove: () => setState(() => _contacts.remove(contact)),
              ),
            _AddTile(
              icon: Icons.person_add_alt,
              label: 'Add Emergency Contact',
              onTap: _addContact,
            ),
            const SizedBox(height: 16),
            _TextField(
              controller: _instructions,
              icon: Icons.notes_outlined,
              label: 'Special Instructions for responders',
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(_saving ? 'Saving…' : 'Save Profile'),
            ),
            const SizedBox(height: 32),
          ],
        ),
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
      padding: const EdgeInsets.fromLTRB(4, 8, 0, 10),
      child: Text(text,
          style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 1)),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _DropdownTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(width: 14),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                items: options
                    .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                    .toList(),
                onChanged: (v) => v != null ? onChanged(v) : null,
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextButtonRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String hint;
  final TextEditingController controller;
  final List<String> chips;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;

  const _TextButtonRow({
    required this.icon,
    required this.label,
    required this.hint,
    required this.controller,
    required this.chips,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textSecondary, size: 22),
              const SizedBox(width: 14),
              Expanded(
                  child: Text(label,
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 14))),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final chip in chips)
                InputChip(
                  label: Text(chip),
                  onDeleted: () => onRemove(chip),
                  deleteIconColor: AppColors.primary,
                  backgroundColor: AppColors.surfaceVariant,
                  side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.2)),
                ),
              if (chips.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('None added',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hint,
                    isDense: true,
                  ),
                  onSubmitted: (_) => onAdd(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle, color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String label;
  final TextInputType? keyboardType;
  final int? maxLines;

  const _TextField({
    required this.controller,
    required this.icon,
    required this.label,
    this.keyboardType,
    this.maxLines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Icon(icon, color: AppColors.textSecondary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              maxLines: maxLines ?? 1,
              decoration: InputDecoration(
                labelText: label,
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
                        color: AppColors.textPrimary, fontSize: 14)),
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

class _ContactTile extends StatelessWidget {
  final EmergencyContact contact;
  final VoidCallback onRemove;

  const _ContactTile({required this.contact, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              contact.name.isNotEmpty ? contact.name[0].toUpperCase() : 'C',
              style: const TextStyle(
                  color: AppColors.primary, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(contact.name,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                Text(
                    '${contact.relationship.isNotEmpty ? '${contact.relationship} · ' : ''}${contact.phone}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AddTile(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(label,
                style: const TextStyle(
                    color: AppColors.primary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
