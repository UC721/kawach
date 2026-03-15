import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Monitors device connectivity and determines ring availability.
///
/// Uses [connectivity_plus] to detect network changes and probes
/// the Supabase backend to confirm cloud reachability.
class ConnectivityMonitor extends ChangeNotifier {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _hasNetwork = false;
  bool _cloudReachable = false;

  bool get hasNetwork => _hasNetwork;
  bool get cloudReachable => _cloudReachable;

  ConnectivityMonitor({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  /// Start listening for connectivity changes.
  Future<void> start() async {
    await _checkConnectivity(await _connectivity.checkConnectivity());
    _subscription =
        _connectivity.onConnectivityChanged.listen(_checkConnectivity);
  }

  Future<void> _checkConnectivity(List<ConnectivityResult> results) async {
    final hadNetwork = _hasNetwork;
    final hadCloud = _cloudReachable;

    _hasNetwork = results.any((r) => r != ConnectivityResult.none);

    if (_hasNetwork) {
      _cloudReachable = await _probeCloud();
    } else {
      _cloudReachable = false;
    }

    if (_hasNetwork != hadNetwork || _cloudReachable != hadCloud) {
      notifyListeners();
    }
  }

  /// Lightweight probe to verify Supabase is reachable.
  Future<bool> _probeCloud() async {
    try {
      await Supabase.instance.client
          .from('emergencies')
          .select('emergency_id')
          .limit(1)
          .timeout(const Duration(seconds: 5));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Force a re-evaluation of connectivity.
  Future<void> refresh() async {
    await _checkConnectivity(await _connectivity.checkConnectivity());
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
