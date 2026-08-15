// ============================================================
// AppColors – KAWACH Brand Palette
// ============================================================

import 'package:flutter/material.dart';

class AppColors {
  static const Color primary      = Color(0xFFE53935); // emergency red
  static const Color secondary    = Color(0xFFFF6F61); // coral accent
  static const Color background   = Color(0xFF0D0D0D); // near-black
  static const Color surface      = Color(0xFF1A1A2E); // deep navy surface
  static const Color surfaceVariant = Color(0xFF252540);
  static const Color danger       = Color(0xFFFF1744);
  static const Color warning      = Color(0xFFFF6D00);
  static const Color safe         = Color(0xFF00E676);
  static const Color textPrimary  = Color(0xFFFFFFFF);
  static const Color textSecondary= Color(0xFF9E9E9E);
  static const Color cardBorder   = Color(0xFF2A2A4A);
}

// ============================================================
// AppRoutes – Named Route Constants
// ============================================================
class AppRoutes {
  static const splash           = '/';
  static const login            = '/login';
  static const dashboard        = '/dashboard';
  static const sos              = '/sos';
  static const map              = '/map';
  static const safeRouteMap     = '/safe-route-map';
  static const safeWalk         = '/safe-walk';
  static const fakeCall         = '/fake-call';
  static const guardianMonitor  = '/guardian-monitor';
  static const report           = '/report';
  static const community        = '/community';
  static const stealthMode      = '/stealth-mode';
  static const emergencyDashboard = '/emergency-dashboard';
  static const guardianNetwork  = '/guardian-network';
  static const riskAlert        = '/risk-alert';
  static const profile          = '/profile';
  static const settings         = '/settings';
}

// ============================================================
// AppStrings
// ============================================================
class AppStrings {
  static const appName     = 'KAWACH';
  static const tagline     = 'Your Shield. Always.';
  static const sosTrigger  = 'SOS ACTIVATED';
  static const stealthHint = 'Emergency running in background';
  static const panicPhrases = [
    'help me',
    'help',
    'stop',
    'leave me alone',
    'bachao',
    'chhodo',
    'madad',
  ];
}

// ============================================================
// AppKeys – Placeholder API Keys (replace before production)
// ============================================================
class AppKeys {
  static const googleMapsApiKey  = 'AIzaSyBCADPPcrSqeHA1jycqDJZejrpGTDgol3w';
  static const smsGatewayUrl     = 'https://api.example.com/sms';
  static const smsGatewayApiKey  = 'YOUR_SMS_GATEWAY_API_KEY';
  static const streamingServerUrl = 'https://stream.example.com/live';
}

// ============================================================
// AppThresholds – Detection Sensitivity Config
// ============================================================
class AppThresholds {
  static const shakeThreshold          = 15.0;  // m/s² magnitude
  static const snatchwatchAccelDelta   = 20.0;  // sudden jerk threshold
  static const locationUpdateInterval  = 5;     // seconds
  static const safeWalkDefaultSeconds  = 1800;  // 30 minutes
  static const highRiskScore           = 7.0;   // out of 10
  static const mediumRiskScore         = 4.0;
  static const dangerZoneRadiusMeters  = 300.0;
  static const sosCountdownSeconds     = 5;     // cancel window
  static const volunteerSearchRadius   = 2000.0; // meters
}

// ============================================================
// MeshDefaults – Mesh Emergency Network Protocol Config
// ============================================================
class MeshDefaults {
  /// Default message time-to-live in seconds (5 minutes).
  static const int ttlSeconds = 300;

  /// Maximum hop count before a message is dropped.
  static const int maxHops = 10;

  /// Expected number of messages in a single bloom-filter generation.
  static const int bloomExpectedItems = 10000;

  /// Target false-positive rate for the deduplication bloom filter.
  static const double bloomFalsePositiveRate = 0.01;

  /// How often (in seconds) the bloom filter should be reset.
  static const int bloomResetIntervalSeconds = 600;

  /// Fallback shared network key (hex-encoded, 256-bit).
  /// In production this is derived per-network via PBKDF2.
  static const String fallbackNetworkKeyHex =
      'a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2';
}

// ============================================================
// FirestoreCollections – Firestore path constants
// ============================================================
class FSCollection {
  static const users          = 'users';
  static const guardians      = 'guardians';
  static const emergencies    = 'emergencies';
  static const reports        = 'reports';
  static const dangerZones    = 'dangerzone';
  static const guardianNetwork= 'guardian_network';
  static const evidenceVault  = 'evidence_vault';
  static const activityLogs   = 'activity_logs';
  static const volunteerAlerts = 'volunteer_alerts';
}
