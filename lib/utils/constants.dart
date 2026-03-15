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
  static const locationHistory = 'location_history';
  static const emergencyEvents = 'emergency_events';
}

// ============================================================
// ScalabilityDefaults – Tuning knobs for millions-of-users scale
// ============================================================
class ScalabilityDefaults {
  // Cache
  static const int memoryCacheMaxItems        = 1000;
  static const int cacheTtlMinutes            = 5;
  static const int userProfileCacheTtlMinutes = 10;
  static const int dangerZoneCacheTtlMinutes  = 30;

  // Rate-limiting (token-bucket)
  static const int rateLimitMaxTokens         = 60;
  static const int rateLimitRefillMs          = 1000;
  static const int rateLimitTokensPerRefill   = 1;

  // Batch processing
  static const int batchMaxSize               = 50;
  static const int batchFlushIntervalMs       = 5000;
  static const int batchMaxRetries            = 3;

  // Circuit breaker
  static const int circuitBreakerFailures     = 5;
  static const int circuitBreakerResetMs      = 30000;
  static const int circuitBreakerSuccesses    = 2;

  // Realtime channels
  static const int maxRealtimeChannels        = 10;
  static const int channelIdleTimeoutMs       = 300000;  // 5 min
  static const int channelReconnectDelayMs    = 3000;

  // Deduplication
  static const int deduplicationWindowMs      = 10000;   // 10 s

  // Connection health
  static const int healthCheckIntervalMs      = 30000;
  static const int maxHealthCheckFailures     = 3;

  // Data partitioning
  static const int geoRegionCount             = 256;
  static const int defaultPageSize            = 50;
}
