// ============================================================
// ApiEndpoints – Backend & third-party endpoint paths
// ============================================================

/// All remote API paths in one place.
class ApiEndpoints {
  ApiEndpoints._();

  // Supabase table names
  static const String users = 'users';
  static const String guardians = 'guardians';
  static const String emergencies = 'emergencies';
  static const String reports = 'reports';
  static const String dangerZones = 'dangerzone';
  static const String guardianNetwork = 'guardian_network';
  static const String evidenceVault = 'evidence_vault';
  static const String activityLogs = 'activity_logs';
  static const String volunteerAlerts = 'volunteer_alerts';

  // Edge-function paths (Supabase Functions)
  static const String triggerSosFunction = '/functions/v1/trigger-sos';
  static const String safetyScoringFunction = '/functions/v1/safety-score';
  static const String routeScoringFunction = '/functions/v1/route-score';

  // External service placeholders
  static const String smsGatewayUrl = 'https://api.example.com/sms';
  static const String streamingServerUrl = 'https://stream.example.com/live';
}
