// ============================================================
// BatteryUtils – Device battery helpers
// ============================================================

/// Utility for battery-aware behaviour.
///
/// Features like mesh networking and continuous monitoring use these
/// checks to throttle polling frequency under low-power conditions.
class BatteryUtils {
  BatteryUtils._();

  /// Threshold below which non-critical background tasks should pause.
  static const int lowBatteryThreshold = 15;

  /// Threshold below which SOS evidence capture switches to audio-only.
  static const int criticalBatteryThreshold = 5;

  /// Determine monitoring interval based on battery level.
  ///
  /// Returns the recommended sensor polling interval in seconds.
  static int recommendedPollingInterval(int batteryPercent) {
    if (batteryPercent <= criticalBatteryThreshold) return 30;
    if (batteryPercent <= lowBatteryThreshold) return 15;
    if (batteryPercent <= 50) return 10;
    return 5;
  }

  /// Whether evidence capture should fall back to audio-only.
  static bool shouldUseAudioOnly(int batteryPercent) {
    return batteryPercent <= criticalBatteryThreshold;
  }

  /// Whether non-critical background services should pause.
  static bool shouldPauseNonCritical(int batteryPercent) {
    return batteryPercent <= lowBatteryThreshold;
  }
}
