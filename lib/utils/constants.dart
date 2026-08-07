import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFFE53935);
  static const Color secondary = Color(0xFFFF6F61);
  static const Color background = Color(0xFFF5F6FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F1F5);
  static const Color danger = Color(0xFFFF1744);
  static const Color warning = Color(0xFFFF6D00);
  static const Color safe = Color(0xFF00C853);
  static const Color textPrimary = Color(0xFF1A1A2E);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color cardBorder = Color(0xFFE5E7EB);
}

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const dashboard = '/dashboard';
  static const sos = '/sos';
  static const map = '/map';
  static const safeRouteMap = '/safe-route-map';
  static const safeWalk = '/safe-walk';
  static const fakeCall = '/fake-call';
  static const guardianMonitor = '/guardian-monitor';
  static const report = '/report';
  static const community = '/community';
  static const stealthMode = '/stealth-mode';
  static const emergencyDashboard = '/emergency-dashboard';
  static const guardianNetwork = '/guardian-network';
  static const riskAlert = '/risk-alert';
  static const profile = '/profile';
  static const settings = '/settings';
  static const onboarding = '/onboarding';
  static const emergencyProfile = '/emergency-profile';
  static const guardianApproval = '/guardian-approval';
  static const incidentHistory = '/incident-history';
  static const privacyConsole = '/privacy-console';
  static const syncStatus = '/sync-status';
}

class AppStrings {
  static const appName = 'KAWACH';
  static const tagline = 'Your Shield. Always.';
  static const sosTrigger = 'SOS ACTIVATED';
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

class AppKeys {
  static const smsGatewayUrl = 'https://api.example.com/sms';
  static const smsGatewayApiKey = 'YOUR_SMS_GATEWAY_API_KEY';
  static const streamingServerUrl = 'https://stream.example.com/live';
  static const emergencyCipherSeed = 'KAWACH_EMERGENCY_CIPHER_V1';
}

class AppThresholds {
  static const shakeThreshold = 15.0;
  static const snatchwatchAccelDelta = 20.0;
  static const locationUpdateInterval = 5;
  static const safeWalkDefaultSeconds = 1800;
  static const highRiskScore = 7.0;
  static const mediumRiskScore = 4.0;
  static const dangerZoneRadiusMeters = 300.0;
  static const sosCountdownSeconds = 5;
  static const volunteerSearchRadius = 2000.0;
  static const aiGuardianFallThreshold = 4.5;
  static const aiGuardianImpactThreshold = 24.0;
  static const aiGuardianSprintThreshold = 16.5;
  static const meshRelayRadiusMeters = 2500.0;
  static const meshPacketTtlMinutes = 20;
  static const evidenceChunkBytes = 262144;
}

class FSCollection {
  static const users = 'users';
  static const guardians = 'guardians';
  static const emergencies = 'sos_alerts';
  static const locations = 'locations';
  static const reports = 'reports';
  static const dangerZones = 'dangerzone';
  static const guardianNetwork = 'guardian_network';
  static const evidenceVault = 'evidence';
  static const activityLogs = 'activity_logs';
  static const volunteerAlerts = 'volunteer_alerts';
  static const meshPackets = 'mesh_packets';
  static const meshAcks = 'mesh_acknowledgements';
  static const emergencyProfiles = 'emergency_profiles';
  static const guardianRequests = 'guardian_requests';
  static const sosAcknowledgements = 'sos_acknowledgements';
}

class FSStorage {
  static const evidenceBucket = 'evidence_bucket';
}
