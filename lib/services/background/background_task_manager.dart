import 'package:flutter/foundation.dart';

/// Priority levels that determine which tasks survive when the system is under
/// resource pressure or the user switches to passive monitoring.
enum TaskPriority {
  /// Must keep running (e.g. location tracking during an emergency).
  critical,

  /// Important but can be paused temporarily (e.g. shake detection).
  high,

  /// Nice-to-have, paused when battery is low (e.g. voice monitoring).
  normal,
}

/// Current execution state of a registered background task.
enum TaskState { running, paused, stopped }

/// Metadata for a single registered background task.
class BackgroundTaskEntry {
  final String id;
  final TaskPriority priority;
  final Future<void> Function() onStart;
  final Future<void> Function() onStop;
  TaskState state;
  DateTime? lastRun;

  BackgroundTaskEntry({
    required this.id,
    required this.priority,
    required this.onStart,
    required this.onStop,
    this.state = TaskState.stopped,
    this.lastRun,
  });
}

/// Manages the registration, lifecycle, and prioritised execution of
/// background tasks.
///
/// Services like [LocationService] or [ShakeService] register themselves as
/// tasks with an [id] and a [TaskPriority].  The manager exposes bulk
/// start/stop/pause operations and lets callers query the state of any task.
class BackgroundTaskManager extends ChangeNotifier {
  final Map<String, BackgroundTaskEntry> _tasks = {};

  // ── Public getters ───────────────────────────────────────────

  /// Returns an unmodifiable view of currently registered tasks.
  Map<String, BackgroundTaskEntry> get tasks =>
      Map.unmodifiable(_tasks);

  /// All tasks that are currently running.
  List<BackgroundTaskEntry> get runningTasks =>
      _tasks.values.where((t) => t.state == TaskState.running).toList();

  /// All tasks that are currently paused.
  List<BackgroundTaskEntry> get pausedTasks =>
      _tasks.values.where((t) => t.state == TaskState.paused).toList();

  /// Whether any task is currently running.
  bool get hasRunningTasks => _tasks.values.any((t) => t.state == TaskState.running);

  // ── Registration ─────────────────────────────────────────────

  /// Registers a background task.
  ///
  /// If a task with the same [id] already exists it will be replaced.
  void registerTask({
    required String id,
    required TaskPriority priority,
    required Future<void> Function() onStart,
    required Future<void> Function() onStop,
  }) {
    _tasks[id] = BackgroundTaskEntry(
      id: id,
      priority: priority,
      onStart: onStart,
      onStop: onStop,
    );
    notifyListeners();
  }

  /// Removes a task registration.  Stops it first if it is running.
  Future<void> unregisterTask(String id) async {
    final task = _tasks[id];
    if (task == null) return;
    if (task.state == TaskState.running) {
      await task.onStop();
    }
    _tasks.remove(id);
    notifyListeners();
  }

  // ── Lifecycle control ────────────────────────────────────────

  /// Starts an individual task by [id].
  Future<void> startTask(String id) async {
    final task = _tasks[id];
    if (task == null || task.state == TaskState.running) return;

    await task.onStart();
    task.state = TaskState.running;
    task.lastRun = DateTime.now();
    notifyListeners();
  }

  /// Stops an individual task by [id].
  Future<void> stopTask(String id) async {
    final task = _tasks[id];
    if (task == null || task.state == TaskState.stopped) return;

    await task.onStop();
    task.state = TaskState.stopped;
    notifyListeners();
  }

  /// Pauses a running task.
  ///
  /// Under the hood this calls [onStop] but records the state as *paused* so
  /// [resumeAll] can restart it later.
  Future<void> pauseTask(String id) async {
    final task = _tasks[id];
    if (task == null || task.state != TaskState.running) return;

    await task.onStop();
    task.state = TaskState.paused;
    notifyListeners();
  }

  // ── Bulk operations ──────────────────────────────────────────

  /// Starts all registered tasks whose priority is >= [minPriority].
  Future<void> startAll({TaskPriority minPriority = TaskPriority.normal}) async {
    for (final task in _tasks.values) {
      if (task.state != TaskState.running &&
          task.priority.index <= minPriority.index) {
        await task.onStart();
        task.state = TaskState.running;
        task.lastRun = DateTime.now();
      }
    }
    notifyListeners();
  }

  /// Stops every running task.
  Future<void> stopAll() async {
    for (final task in _tasks.values) {
      if (task.state == TaskState.running) {
        await task.onStop();
        task.state = TaskState.stopped;
      }
    }
    notifyListeners();
  }

  /// Pauses non-critical tasks (priority > [keepPriority]).
  ///
  /// This is useful when the device is low on battery or entering a power-save
  /// mode – critical tasks keep running while lower-priority ones are paused.
  Future<void> pauseNonCritical(
      {TaskPriority keepPriority = TaskPriority.critical}) async {
    for (final task in _tasks.values) {
      if (task.state == TaskState.running &&
          task.priority.index > keepPriority.index) {
        await task.onStop();
        task.state = TaskState.paused;
      }
    }
    notifyListeners();
  }

  /// Resumes all tasks that were previously paused.
  Future<void> resumeAll() async {
    for (final task in _tasks.values) {
      if (task.state == TaskState.paused) {
        await task.onStart();
        task.state = TaskState.running;
        task.lastRun = DateTime.now();
      }
    }
    notifyListeners();
  }

  // ── Query helpers ────────────────────────────────────────────

  /// Returns the state of a task, or `null` if not registered.
  TaskState? getTaskState(String id) => _tasks[id]?.state;

  /// Whether the given task is registered.
  bool isRegistered(String id) => _tasks.containsKey(id);

  @override
  void dispose() {
    // Best-effort synchronous cleanup; callers should [stopAll] before dispose.
    for (final task in _tasks.values) {
      if (task.state == TaskState.running) {
        task.onStop();
      }
    }
    _tasks.clear();
    super.dispose();
  }
}
