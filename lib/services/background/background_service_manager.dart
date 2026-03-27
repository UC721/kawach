import 'dart:async';

// ============================================================
// BackgroundServiceManager – flutter_background_service integration
// ============================================================

/// Manages long-running background tasks for continuous safety
/// monitoring when the app is minimised or the screen is off.
///
/// Coordinates [MonitoringIsolate] and [SensorPoller] within
/// a foreground service (Android) or background mode (iOS).
class BackgroundServiceManager {
  bool _isRunning = false;
  bool get isRunning => _isRunning;

  /// Initialise and start the background service.
  Future<void> startService() async {
    if (_isRunning) return;
    _isRunning = true;
    // In production:
    // 1. Configure flutter_background_service
    // 2. Start foreground notification (Android)
    // 3. Register background fetch (iOS)
    // 4. Launch monitoring isolate
  }

  /// Stop the background service.
  Future<void> stopService() async {
    _isRunning = false;
    // In production:
    // 1. Cancel foreground notification
    // 2. Stop isolate
  }

  /// Check if the service is currently active.
  Future<bool> isServiceRunning() async {
    return _isRunning;
  }

  /// Update the foreground notification content.
  Future<void> updateNotification({
    required String title,
    required String body,
  }) async {
    // In production: update via flutter_background_service
  }
}
