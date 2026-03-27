import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

// ============================================================
// ConnectivityService – Network reachability monitor
// ============================================================

/// Reactive connectivity state used by offline-first logic.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isOnline = true;
  bool get isOnline => _isOnline;

  /// Begin listening for connectivity changes.
  void startMonitoring() {
    _subscription = _connectivity.onConnectivityChanged.listen(_update);
  }

  void _update(List<ConnectivityResult> results) {
    _isOnline = results.any((r) => r != ConnectivityResult.none);
  }

  /// Check current connectivity once.
  Future<bool> checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _isOnline = results.any((r) => r != ConnectivityResult.none);
    return _isOnline;
  }

  void dispose() {
    _subscription?.cancel();
  }
}
