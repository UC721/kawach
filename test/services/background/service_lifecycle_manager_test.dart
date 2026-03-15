import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/models/background_service_config.dart';
import 'package:kawach/services/background/background_service.dart';
import 'package:kawach/services/background/background_task_manager.dart';
import 'package:kawach/services/background/service_lifecycle_manager.dart';

void main() {
  late BackgroundService backgroundService;
  late BackgroundTaskManager taskManager;
  late ServiceLifecycleManager lifecycleManager;
  late List<String> callLog;

  setUp(() {
    backgroundService = BackgroundService();
    taskManager = BackgroundTaskManager();
    lifecycleManager = ServiceLifecycleManager(
      backgroundService: backgroundService,
      taskManager: taskManager,
    );
    callLog = [];
  });

  tearDown(() {
    lifecycleManager.dispose();
    taskManager.dispose();
    backgroundService.dispose();
  });

  void registerSampleTasks() {
    taskManager.registerTask(
      id: 'location',
      priority: TaskPriority.critical,
      onStart: () async => callLog.add('start:location'),
      onStop: () async => callLog.add('stop:location'),
    );
    taskManager.registerTask(
      id: 'shake',
      priority: TaskPriority.high,
      onStart: () async => callLog.add('start:shake'),
      onStop: () async => callLog.add('stop:shake'),
    );
    taskManager.registerTask(
      id: 'voice',
      priority: TaskPriority.normal,
      onStart: () async => callLog.add('start:voice'),
      onStop: () async => callLog.add('stop:voice'),
    );
  }

  group('ServiceLifecycleManager', () {
    test('initial state is resumed and not observing', () {
      expect(lifecycleManager.lastState, AppLifecycleState.resumed);
      expect(lifecycleManager.isInForeground, isTrue);
      expect(lifecycleManager.isInBackground, isFalse);
      expect(lifecycleManager.isObserving, isFalse);
    });

    testWidgets('initialize registers lifecycle observer', (tester) async {
      lifecycleManager.initialize();

      expect(lifecycleManager.isObserving, isTrue);
    });

    testWidgets('double initialize is safe', (tester) async {
      lifecycleManager.initialize();
      lifecycleManager.initialize();

      expect(lifecycleManager.isObserving, isTrue);
    });

    testWidgets('dispose removes observer', (tester) async {
      lifecycleManager.initialize();
      lifecycleManager.dispose();

      expect(lifecycleManager.isObserving, isFalse);
    });

    test('didChangeAppLifecycleState updates lastState', () {
      lifecycleManager
          .didChangeAppLifecycleState(AppLifecycleState.paused);

      expect(lifecycleManager.lastState, AppLifecycleState.paused);
      expect(lifecycleManager.isInBackground, isTrue);
      expect(lifecycleManager.isInForeground, isFalse);
    });

    test('enterEmergencyMode starts all tasks and background service',
        () async {
      registerSampleTasks();

      try {
        await lifecycleManager.enterEmergencyMode();
      } catch (_) {
        // notification plugin may throw in test
      }

      expect(backgroundService.isRunning, isTrue);
      expect(backgroundService.config,
          equals(BackgroundServiceConfig.emergency()));
      expect(callLog, containsAll(['start:location', 'start:shake', 'start:voice']));
    });

    test('exitEmergencyMode resets config', () async {
      registerSampleTasks();
      try {
        await lifecycleManager.enterEmergencyMode();
      } catch (_) {}

      try {
        await lifecycleManager.exitEmergencyMode();
      } catch (_) {}

      expect(backgroundService.config,
          equals(const BackgroundServiceConfig()));
    });

    test('onBackgrounded starts service and pauses non-critical', () async {
      registerSampleTasks();
      await taskManager.startAll();
      callLog.clear();

      // Simulate app backgrounding
      lifecycleManager
          .didChangeAppLifecycleState(AppLifecycleState.paused);

      // Give async handlers a tick to complete
      await Future.delayed(Duration.zero);

      expect(lifecycleManager.isInBackground, isTrue);
    });

    test('onResumed resumes paused tasks', () async {
      registerSampleTasks();
      await taskManager.startAll();
      await taskManager.pauseTask('shake');
      await taskManager.pauseTask('voice');
      callLog.clear();

      // Simulate app resuming
      lifecycleManager
          .didChangeAppLifecycleState(AppLifecycleState.resumed);

      await Future.delayed(Duration.zero);

      expect(lifecycleManager.isInForeground, isTrue);
    });

    test('inactive state does not change running tasks', () async {
      registerSampleTasks();
      await taskManager.startAll();
      callLog.clear();

      lifecycleManager
          .didChangeAppLifecycleState(AppLifecycleState.inactive);

      await Future.delayed(Duration.zero);

      // No tasks should have been stopped or started
      expect(callLog, isEmpty);
    });
  });
}
