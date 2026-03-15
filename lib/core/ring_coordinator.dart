import 'package:flutter/foundation.dart';

import 'ring.dart';
import 'connectivity_monitor.dart';
import 'edge_ring.dart';
import 'mesh_ring.dart';
import 'cloud_ring.dart';

/// Orchestrates the three concentric rings of KAWACH.
///
/// Monitors connectivity via [ConnectivityMonitor] and maintains a
/// [RingState] that drives which capabilities are available.
///
/// Degradation chain: Cloud → Mesh → Edge (always available).
class RingCoordinator extends ChangeNotifier {
  final ConnectivityMonitor connectivity;
  final EdgeRing edgeRing;
  final MeshRing meshRing;
  final CloudRing cloudRing;

  late RingState _state;

  RingCoordinator({
    required this.connectivity,
    EdgeRing? edgeRing,
    MeshRing? meshRing,
    CloudRing? cloudRing,
  })  : edgeRing = edgeRing ?? EdgeRing(),
        meshRing = meshRing ?? MeshRing(),
        cloudRing = cloudRing ?? CloudRing() {
    _state = RingState(
      edgeAvailable: true,
      meshAvailable: connectivity.hasNetwork,
      cloudAvailable: connectivity.cloudReachable,
      updatedAt: DateTime.now(),
    );
    connectivity.addListener(_onConnectivityChanged);
  }

  /// Current state of all three rings.
  RingState get state => _state;

  /// The outermost ring that is currently operational.
  Ring get activeRing => _state.activeRing;

  /// Whether the cloud backend is reachable right now.
  bool get isCloudAvailable => _state.cloudAvailable;

  /// Whether mesh relay (SMS / guardian network) is operational.
  bool get isMeshAvailable => _state.meshAvailable;

  void _onConnectivityChanged() {
    _state = _state.copyWith(
      meshAvailable: connectivity.hasNetwork,
      cloudAvailable: connectivity.cloudReachable,
    );
    debugPrint('[RingCoordinator] $_state');
    notifyListeners();
  }

  /// Force a re-evaluation of ring availability.
  Future<void> refresh() async {
    await connectivity.refresh();
  }

  @override
  void dispose() {
    connectivity.removeListener(_onConnectivityChanged);
    super.dispose();
  }
}
