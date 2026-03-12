import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  // ── Request all permissions at once ─────────────────────────
  static Future<bool> requestAllPermissions() async {
    final statuses = await [
      Permission.location,
      Permission.locationAlways,
      Permission.microphone,
      Permission.camera,
      Permission.phone,
      Permission.notification,
      Permission.storage,
    ].request();

    return statuses.values.every(
      (status) =>
          status.isGranted || status.isLimited,
    );
  }

  // ── Individual checks ────────────────────────────────────────
  static Future<bool> checkLocation() async {
    return await Permission.location.isGranted;
  }

  static Future<bool> checkMicrophone() async {
    return await Permission.microphone.isGranted;
  }

  static Future<bool> checkCamera() async {
    return await Permission.camera.isGranted;
  }

  // ── Show rationale dialog ────────────────────────────────────
  static Future<void> showPermissionRationale(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onGoToSettings,
  }) async {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onGoToSettings();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // ── Open app settings ────────────────────────────────────────
  static Future<void> openSettings() async {
    await openAppSettings();
  }

  // ── Request location always (background) ────────────────────
  static Future<bool> requestBackgroundLocation() async {
    if (await Permission.location.isGranted) {
      final status = await Permission.locationAlways.request();
      return status.isGranted;
    }
    return false;
  }
}
