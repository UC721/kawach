import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../models/background_service_config.dart';
import 'background_service.dart';
import 'background_task_manager.dart';

/// Observes the application lifecycle (foreground ↔ background) and
/// coordinates [BackgroundService] + [BackgroundTaskManager] accordingly.
///
/// ```
///  App resumed  ──▶  restart paused tasks, cancel notification
///  App paused   ──▶  start foreground service, keep critical tasks
///  App detached ──▶  same as paused (process may be killed soon)
/// ```
class ServiceLifecycleManager extends ChangeNotifier
    with WidgetsBindingObserver {
  final BackgroundService backgroundService;
  final BackgroundTaskManager taskManager;

  AppLifecycleState _lastState = AppLifecycleState.resumed;

  /// Whether the manager has been [initialize]d and is observing lifecycle.
  bool _observing = false;

  ServiceLifecycleManager({
    required this.backgroundService,
    required this.taskManager,
  });

  // ── Public getters ───────────────────────────────────────────

  AppLifecycleState get lastState => _lastState;
  bool get isInBackground =>
      _lastState == AppLifecycleState.paused ||
      _lastState == AppLifecycleState.detached;
  bool get isInForeground => _lastState == AppLifecycleState.resumed;
  bool get isObserving => _observing;

  // ── Setup / Teardown ─────────────────────────────────────────

  /// Registers this instance as a lifecycle observer.
  ///
  /// Must be called once after the [WidgetsBinding] is initialised (e.g. in
  /// `main()` after `WidgetsFlutterBinding.ensureInitialized()`).
  void initialize() {
    if (_observing) return;
    WidgetsBinding.instance.addObserver(this);
    _observing = true;
  }

  // ── Lifecycle callbacks ──────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lastState = state;
    notifyListeners();

    switch (state) {
      case AppLifecycleState.resumed:
        _onResumed();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _onBackgrounded();
        break;
      case AppLifecycleState.inactive:
        // Transition state – no action needed.
        break;
      case AppLifecycleState.hidden:
        break;
    }
  }

  // ── Internal transitions ─────────────────────────────────────

  /// Called when the app returns to the foreground.
  Future<void> _onResumed() async {
    // Re-start any tasks that were paused when backgrounded.
    await taskManager.resumeAll();

    // Remove the foreground notification – the app is visible again.
    await backgroundService.stopService(force: true);
  }

  /// Called when the app moves to the background (or is about to be killed).
  Future<void> _onBackgrounded() async {
    // Start the foreground service so the OS keeps the process alive.
    await backgroundService.startService(
      config: backgroundService.config,
    );

    // Pause non-critical tasks to save resources.
    await taskManager.pauseNonCritical();
  }

  /// Convenience: switch to emergency configuration.
  ///
  /// Promotes all tasks to running, switches to the emergency notification,
  /// and ensures the foreground service is active regardless of lifecycle.
  Future<void> enterEmergencyMode() async {
    await backgroundService.updateConfig(
      BackgroundServiceConfig.emergency(),
    );
    await backgroundService.startService(
      config: BackgroundServiceConfig.emergency(),
    );
    await taskManager.startAll();
  }

  /// Convenience: leave emergency mode and return to default monitoring.
  Future<void> exitEmergencyMode() async {
    await backgroundService.updateConfig(
      const BackgroundServiceConfig(),
    );

    if (isInForeground) {
      await backgroundService.stopService(force: true);
      await taskManager.resumeAll();
    }
  }

  @override
  void dispose() {
    if (_observing) {
      WidgetsBinding.instance.removeObserver(this);
      _observing = false;
    }
    super.dispose();
  }
}
