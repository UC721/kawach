/// Application-wide constants for KAWACH.
class AppConstants {
  AppConstants._();

  // SOS
  static const int sosMaxPerWindow = 3;
  static const Duration sosRateLimitWindow = Duration(minutes: 10);
  static const Duration sosConfirmationTimeout = Duration(seconds: 5);

  // Mesh network
  static const int meshTtlHops = 7;
  static const Duration meshMessageTtl = Duration(hours: 24);
  static const int meshBloomFilterSize = 10000;
  static const String meshServiceUuid = '00001800-0000-1000-8000-00805f9b34fb';
  static const String meshCharacteristicUuid =
      '00002a00-0000-1000-8000-00805f9b34fb';

  // Evidence
  static const int evidenceSignedUrlMinutes = 15;
  static const int maxEvidenceFileSizeMb = 100;

  // Location
  static const int locationUpdateIntervalSec = 10;
  static const int geohashPrecision = 5; // ~5 km² for CrowdShield

  // CrowdShield
  static const double crowdShieldRadiusMeters = 500;

  // Safe walk
  static const Duration safeWalkCheckInInterval = Duration(minutes: 2);

  // Background
  static const String backgroundServiceId = 'kawach_bg_service';
  static const Duration sensorPollInterval = Duration(milliseconds: 200);

  // Battery gate for ML models
  static const int mlBatteryThresholdPercent = 20;

  // Guardian
  static const Duration guardianRemovalCooldown = Duration(hours: 48);
}
