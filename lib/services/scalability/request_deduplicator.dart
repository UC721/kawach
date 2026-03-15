import '../../models/scalability_config_model.dart';

/// Prevents duplicate requests within a configurable time window.
///
/// In emergency scenarios users may frantically press the SOS button
/// multiple times.  The [RequestDeduplicator] ensures that only one
/// SOS trigger reaches the backend per deduplication window, avoiding
/// duplicate database rows and guardian alerts.
class RequestDeduplicator {
  final ScalabilityConfig _config;

  /// Key → first-seen timestamp.
  final Map<String, DateTime> _seen = {};

  RequestDeduplicator({ScalabilityConfig? config})
      : _config = config ?? const ScalabilityConfig();

  /// Check whether [key] is a duplicate.
  ///
  /// Returns `true` if this is the first time [key] has been seen
  /// within the deduplication window (i.e. the request should
  /// proceed).  Returns `false` if the request is a duplicate.
  bool shouldProcess(String key) {
    _purge();
    if (_seen.containsKey(key)) return false;
    _seen[key] = DateTime.now();
    return true;
  }

  /// Whether [key] has been seen within the window.
  bool isDuplicate(String key) {
    _purge();
    return _seen.containsKey(key);
  }

  /// Remove stale entries.
  void _purge() {
    final cutoff = DateTime.now().subtract(_config.deduplicationWindow);
    _seen.removeWhere((_, ts) => ts.isBefore(cutoff));
  }

  /// Manually remove a key (e.g. after a confirmed cancel).
  void remove(String key) {
    _seen.remove(key);
  }

  /// Clear all tracking state.
  void clear() {
    _seen.clear();
  }

  int get trackedCount {
    _purge();
    return _seen.length;
  }
}
