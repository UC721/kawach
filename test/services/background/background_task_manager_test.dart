import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/services/background/background_task_manager.dart';

void main() {
  late BackgroundTaskManager manager;
  late List<String> callLog;

  setUp(() {
    manager = BackgroundTaskManager();
    callLog = [];
  });

  tearDown(() {
    manager.dispose();
  });

  BackgroundTaskEntry _register(
    String id, {
    TaskPriority priority = TaskPriority.normal,
  }) {
    manager.registerTask(
      id: id,
      priority: priority,
      onStart: () async => callLog.add('start:$id'),
      onStop: () async => callLog.add('stop:$id'),
    );
    return manager.tasks[id]!;
  }

  group('BackgroundTaskManager', () {
    test('registerTask adds a new task', () {
      _register('location');

      expect(manager.isRegistered('location'), isTrue);
      expect(manager.tasks.length, 1);
    });

    test('unregisterTask removes task and stops it if running', () async {
      _register('location');
      await manager.startTask('location');

      await manager.unregisterTask('location');

      expect(manager.isRegistered('location'), isFalse);
      expect(callLog, contains('stop:location'));
    });

    test('unregisterTask does nothing for unknown id', () async {
      await manager.unregisterTask('nonexistent');
      expect(manager.tasks, isEmpty);
    });

    test('startTask transitions state to running', () async {
      _register('shake', priority: TaskPriority.high);

      await manager.startTask('shake');

      expect(manager.getTaskState('shake'), TaskState.running);
      expect(callLog, ['start:shake']);
    });

    test('startTask is a no-op when already running', () async {
      _register('shake');
      await manager.startTask('shake');
      callLog.clear();

      await manager.startTask('shake');

      expect(callLog, isEmpty);
    });

    test('stopTask transitions state to stopped', () async {
      _register('voice');
      await manager.startTask('voice');

      await manager.stopTask('voice');

      expect(manager.getTaskState('voice'), TaskState.stopped);
      expect(callLog, contains('stop:voice'));
    });

    test('stopTask is a no-op when already stopped', () async {
      _register('voice');

      await manager.stopTask('voice');

      expect(callLog, isEmpty);
    });

    test('pauseTask marks running task as paused', () async {
      _register('motion');
      await manager.startTask('motion');

      await manager.pauseTask('motion');

      expect(manager.getTaskState('motion'), TaskState.paused);
      expect(callLog, contains('stop:motion'));
    });

    test('pauseTask ignores non-running tasks', () async {
      _register('motion');

      await manager.pauseTask('motion');

      expect(manager.getTaskState('motion'), TaskState.stopped);
      expect(callLog, isEmpty);
    });

    test('startAll starts all stopped tasks', () async {
      _register('a', priority: TaskPriority.critical);
      _register('b', priority: TaskPriority.high);
      _register('c', priority: TaskPriority.normal);

      await manager.startAll();

      expect(manager.runningTasks.length, 3);
      expect(callLog, containsAll(['start:a', 'start:b', 'start:c']));
    });

    test('startAll with minPriority filters tasks', () async {
      _register('critical', priority: TaskPriority.critical);
      _register('high', priority: TaskPriority.high);
      _register('normal', priority: TaskPriority.normal);

      await manager.startAll(minPriority: TaskPriority.high);

      expect(manager.getTaskState('critical'), TaskState.running);
      expect(manager.getTaskState('high'), TaskState.running);
      expect(manager.getTaskState('normal'), TaskState.stopped);
    });

    test('stopAll stops every running task', () async {
      _register('a');
      _register('b');
      await manager.startAll();
      callLog.clear();

      await manager.stopAll();

      expect(manager.runningTasks, isEmpty);
      expect(callLog, containsAll(['stop:a', 'stop:b']));
    });

    test('pauseNonCritical pauses only lower-priority tasks', () async {
      _register('critical', priority: TaskPriority.critical);
      _register('high', priority: TaskPriority.high);
      _register('normal', priority: TaskPriority.normal);
      await manager.startAll();

      await manager.pauseNonCritical();

      expect(manager.getTaskState('critical'), TaskState.running);
      expect(manager.getTaskState('high'), TaskState.paused);
      expect(manager.getTaskState('normal'), TaskState.paused);
    });

    test('resumeAll restarts paused tasks', () async {
      _register('a');
      _register('b');
      await manager.startAll();
      await manager.pauseTask('a');
      await manager.pauseTask('b');
      callLog.clear();

      await manager.resumeAll();

      expect(manager.runningTasks.length, 2);
      expect(callLog, containsAll(['start:a', 'start:b']));
    });

    test('resumeAll does not restart stopped tasks', () async {
      _register('a');
      _register('b');
      await manager.startTask('a');
      await manager.pauseTask('a');
      callLog.clear();

      await manager.resumeAll();

      // Only 'a' was paused, 'b' was still stopped
      expect(manager.getTaskState('a'), TaskState.running);
      expect(manager.getTaskState('b'), TaskState.stopped);
      expect(callLog, ['start:a']);
    });

    test('hasRunningTasks reports correctly', () async {
      _register('x');

      expect(manager.hasRunningTasks, isFalse);

      await manager.startTask('x');
      expect(manager.hasRunningTasks, isTrue);

      await manager.stopTask('x');
      expect(manager.hasRunningTasks, isFalse);
    });

    test('getTaskState returns null for unknown id', () {
      expect(manager.getTaskState('ghost'), isNull);
    });

    test('lastRun is set when task starts', () async {
      _register('loc');
      final before = DateTime.now();

      await manager.startTask('loc');

      final entry = manager.tasks['loc']!;
      expect(entry.lastRun, isNotNull);
      expect(entry.lastRun!.isAfter(before) || entry.lastRun == before, isTrue);
    });

    test('re-registering a task replaces the previous entry', () async {
      _register('dup');
      await manager.startTask('dup');

      // Re-register with a different priority
      manager.registerTask(
        id: 'dup',
        priority: TaskPriority.critical,
        onStart: () async => callLog.add('start:dup_v2'),
        onStop: () async => callLog.add('stop:dup_v2'),
      );

      expect(manager.tasks['dup']!.priority, TaskPriority.critical);
      // New entry starts in stopped state
      expect(manager.getTaskState('dup'), TaskState.stopped);
    });
  });
}
