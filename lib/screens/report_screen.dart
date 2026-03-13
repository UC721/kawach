import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:uuid/uuid.dart';

import '../models/report_model.dart';
import '../services/location_service.dart';
import '../services/danger_zone_service.dart';
import '../utils/constants.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _descCtrl = TextEditingController();
  XFile? _image;
  bool _isSubmitting = false;
  Position? _position;

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  Future<void> _getLocation() async {
    try {
      _position =
          await context.read<LocationService>().getCurrentPosition();
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => _image = picked);
    }
  }

  Future<void> _submitReport() async {
    if (_descCtrl.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);

    try {
      final uid = Supabase.instance.client.auth.currentUser?.id ?? 'anon';
      String? imageUrl;

      if (_image != null) {
        final fileName = '${const Uuid().v4()}.jpg';
        final path = 'reports/$uid/$fileName';
        
        final bytes = await _image!.readAsBytes();
        
        await Supabase.instance.client.storage.from('incident-photos').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );
        imageUrl = Supabase.instance.client.storage.from('incident-photos').getPublicUrl(path);
      }

      final report = ReportModel(
        reportId: const Uuid().v4(),
        userId: uid,
        description: _descCtrl.text.trim(),
        imageUrl: imageUrl,
        lat: _position?.latitude,
        lng: _position?.longitude,
        createdAt: DateTime.now(),
      );

      await Supabase.instance.client
          .from(FSCollection.reports)
          .insert(report.toMap());

      // Trigger danger zone aggregation
      await context.read<DangerZoneService>().aggregateFromReports();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Report submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Report Incident')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.warning.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline,
                      color: AppColors.warning, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your report contributes to the community safety heatmap and helps warn others.',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('Describe the Incident',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            TextFormField(
              controller: _descCtrl,
              maxLines: 5,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'What happened? Where? When?',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            const Text('Add Photo Evidence (Optional)',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: kIsWeb
                            ? Image.network(_image!.path, fit: BoxFit.cover)
                            : Image.file(File(_image!.path), fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt_outlined,
                              color: AppColors.textSecondary, size: 40),
                          SizedBox(height: 8),
                          Text('Tap to take a photo',
                              style: TextStyle(
                                  color: AppColors.textSecondary)),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 16),
            if (_position != null)
              Row(
                children: [
                  const Icon(Icons.location_pin,
                      color: AppColors.primary, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Location auto-attached: ${_position!.latitude.toStringAsFixed(4)}, ${_position!.longitude.toStringAsFixed(4)}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isSubmitting ? null : _submitReport,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded),
                label: const Text('Submit Report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
