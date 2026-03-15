import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../models/scalability_config_model.dart';

/// A pending batch operation.
class BatchOperation {
  final String table;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  int _attempts;

  BatchOperation({
    required this.table,
    required this.data,
  })  : createdAt = DateTime.now(),
        _attempts = 0;

  int get attempts => _attempts;
  void incrementAttempts() => _attempts++;
}

/// Collects database writes into batches and flushes them
/// periodically or when the batch is full.
///
/// For location-tracking at scale (millions of users updating every
/// few seconds), individual inserts would overwhelm the database.
/// The [BatchProcessor] groups writes by table and flushes them in a
/// single round-trip, dramatically reducing connection pressure.
class BatchProcessor extends ChangeNotifier {
  final ScalabilityConfig _config;

  /// Callback executed when a batch is flushed.
  /// Receives the table name and list of row maps.
  final Future<void> Function(String table, List<Map<String, dynamic>> rows)?
      onFlush;

  /// Queued operations grouped by table.
  final Map<String, List<BatchOperation>> _queues = {};

  Timer? _flushTimer;
  bool _isFlushing = false;
  int _totalFlushed = 0;
  int _totalFailed = 0;

  bool get isFlushing => _isFlushing;
  int get totalFlushed => _totalFlushed;
  int get totalFailed => _totalFailed;
  int get pendingCount =>
      _queues.values.fold(0, (sum, q) => sum + q.length);

  BatchProcessor({
    ScalabilityConfig? config,
    this.onFlush,
  }) : _config = config ?? const ScalabilityConfig();

  /// Start the periodic flush timer.
  void start() {
    _flushTimer?.cancel();
    _flushTimer = Timer.periodic(
      _config.batchFlushInterval,
      (_) => flush(),
    );
  }

  /// Enqueue one write operation.
  void enqueue(String table, Map<String, dynamic> data) {
    final op = BatchOperation(table: table, data: data);
    _queues.putIfAbsent(table, () => []).add(op);

    // Flush immediately if the batch is full.
    if (_queues[table]!.length >= _config.batchMaxSize) {
      _flushTable(table);
    }
  }

  /// Flush all pending batches.
  Future<void> flush() async {
    if (_isFlushing) return;
    _isFlushing = true;
    notifyListeners();

    try {
      final tables = List<String>.from(_queues.keys);
      for (final table in tables) {
        await _flushTable(table);
      }
    } finally {
      _isFlushing = false;
      notifyListeners();
    }
  }

  Future<void> _flushTable(String table) async {
    final queue = _queues[table];
    if (queue == null || queue.isEmpty) return;

    // Take the current batch.
    final batch = List<BatchOperation>.from(queue);
    queue.clear();

    try {
      if (onFlush != null) {
        await onFlush!(table, batch.map((op) => op.data).toList());
      }
      _totalFlushed += batch.length;
    } catch (_) {
      // Re-enqueue operations that haven't exceeded retry limit.
      for (final op in batch) {
        op.incrementAttempts();
        if (op.attempts < _config.batchMaxRetries) {
          _queues.putIfAbsent(table, () => []).add(op);
        } else {
          _totalFailed++;
        }
      }
    }
  }

  /// Stop the flush timer and drain remaining operations.
  Future<void> stop() async {
    _flushTimer?.cancel();
    _flushTimer = null;
    await flush();
  }

  @override
  void dispose() {
    _flushTimer?.cancel();
    super.dispose();
  }
}
