import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../models/background_service_config.dart';

/// Manages the Android foreground-service notification and overall
/// background-service lifecycle.
///
/// On Android a persistent notification is required to keep the app alive when
/// backgrounded.  On iOS the equivalent is handled by background modes declared
/// in Info.plist; this service coordinates the Dart-side bookkeeping for both.
class BackgroundService extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  BackgroundServiceConfig _config = const BackgroundServiceConfig();
  bool _isRunning = false;
  DateTime? _startedAt;

  /// Android notification channel used for the foreground service.
  static const _channelId = 'kawach_background';
  static const _channelName = 'KAWACH Background Service';
  static const _channelDesc =
      'Keeps safety monitoring active in the background';
  static const _notificationId = 9001;

  // ── Public getters ───────────────────────────────────────────
  bool get isRunning => _isRunning;
  DateTime? get startedAt => _startedAt;
  BackgroundServiceConfig get config => _config;

  /// Duration the service has been running, or [Duration.zero] if stopped.
  Duration get uptime =>
      _startedAt != null ? DateTime.now().difference(_startedAt!) : Duration.zero;

  // ── Initialization ───────────────────────────────────────────
  Future<void> initialize() async {
    if (kIsWeb) return;

    const androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _notifications.initialize(settings: initSettings);
  }

  // ── Start / Stop ─────────────────────────────────────────────

  /// Starts the background service with the given [config].
  ///
  /// Shows a persistent foreground notification on Android so the OS does not
  /// kill the app.  Returns immediately on web.
  Future<void> startService({BackgroundServiceConfig? config}) async {
    if (_isRunning) return;

    _config = config ?? const BackgroundServiceConfig();
    _isRunning = true;
    _startedAt = DateTime.now();
    notifyListeners();

    await _showForegroundNotification();
  }

  /// Stops the background service and removes the foreground notification.
  ///
  /// If [autoStopThresholdSec] has not elapsed and [force] is false the
  /// request is ignored to prevent accidental teardown.
  Future<void> stopService({bool force = false}) async {
    if (!_isRunning) return;

    if (!force && _startedAt != null) {
      final elapsed = DateTime.now().difference(_startedAt!).inSeconds;
      if (elapsed < _config.autoStopThresholdSec) return;
    }

    _isRunning = false;
    _startedAt = null;
    notifyListeners();

    await _cancelForegroundNotification();
  }

  // ── Update config at runtime ─────────────────────────────────

  /// Replaces the active configuration and refreshes the notification text.
  Future<void> updateConfig(BackgroundServiceConfig newConfig) async {
    _config = newConfig;
    notifyListeners();

    if (_isRunning) {
      await _showForegroundNotification();
    }
  }

  // ── Foreground notification helpers ──────────────────────────

  Future<void> _showForegroundNotification() async {
    if (kIsWeb) return;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDesc,
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showWhen: false,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: false,
      presentSound: false,
    );

    await _notifications.show(
      _notificationId,
      _config.notificationTitle,
      _config.notificationBody,
      NotificationDetails(android: androidDetails, iOS: iosDetails),
    );
  }

  Future<void> _cancelForegroundNotification() async {
    if (kIsWeb) return;
    await _notifications.cancel(_notificationId);
  }

  @override
  void dispose() {
    _cancelForegroundNotification();
    super.dispose();
  }
}
