// ============================================================
// AppConstants – Global application constants
// ============================================================

/// Centralised constants used across all feature modules.
class AppConstants {
  AppConstants._();

  static const String appName = 'KAWACH';
  static const String tagline = 'Your Shield. Always.';

  // SOS
  static const int sosCountdownSeconds = 5;
  static const int evidenceRecordingMinutes = 5;

  // Detection thresholds
  static const double shakeThresholdMs2 = 15.0;
  static const double snatchwatchAccelDelta = 20.0;
  static const double dangerZoneRadiusMeters = 300.0;
  static const double highRiskScore = 7.0;
  static const double mediumRiskScore = 4.0;
  static const double volunteerSearchRadiusMeters = 2000.0;

  // Timing
  static const int locationUpdateIntervalSec = 5;
  static const int safeWalkDefaultSeconds = 1800;

  // Mesh network
  static const int meshTtlDefault = 5;
  static const int dedupCacheTtlSeconds = 300;
  static const int bleScanDurationSeconds = 10;

  // Panic phrases (multi-language)
  static const List<String> panicPhrases = [
    'help me', 'help', 'stop', 'leave me alone',
    'bachao', 'chhodo', 'madad',
  ];
}
