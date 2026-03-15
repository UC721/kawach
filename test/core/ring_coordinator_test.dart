import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/core/ring.dart';
import 'package:kawach/core/connectivity_monitor.dart';
import 'package:kawach/core/ring_coordinator.dart';
import 'package:kawach/core/edge_ring.dart';
import 'package:kawach/core/mesh_ring.dart';
import 'package:kawach/core/cloud_ring.dart';

/// Minimal stub of [ConnectivityMonitor] for unit tests.
///
/// Does not perform actual network checks; instead exposes setters
/// so tests can simulate connectivity changes.
class FakeConnectivityMonitor extends ConnectivityMonitor {
  bool _fakeNetwork;
  bool _fakeCloud;

  FakeConnectivityMonitor({
    bool hasNetwork = false,
    bool cloudReachable = false,
  })  : _fakeNetwork = hasNetwork,
        _fakeCloud = cloudReachable;

  @override
  bool get hasNetwork => _fakeNetwork;

  @override
  bool get cloudReachable => _fakeCloud;

  void setNetwork(bool value) {
    _fakeNetwork = value;
    notifyListeners();
  }

  void setCloud(bool value) {
    _fakeCloud = value;
    notifyListeners();
  }
}

void main() {
  group('RingCoordinator', () {
    late FakeConnectivityMonitor monitor;
    late RingCoordinator coordinator;

    setUp(() {
      monitor = FakeConnectivityMonitor();
      coordinator = RingCoordinator(connectivity: monitor);
    });

    tearDown(() {
      coordinator.dispose();
      monitor.dispose();
    });

    test('initial state: edge only when no network', () {
      expect(coordinator.activeRing, Ring.edge);
      expect(coordinator.isCloudAvailable, isFalse);
      expect(coordinator.isMeshAvailable, isFalse);
      expect(coordinator.state.edgeAvailable, isTrue);
    });

    test('mesh becomes available when network connects', () {
      monitor.setNetwork(true);
      expect(coordinator.isMeshAvailable, isTrue);
      expect(coordinator.activeRing, Ring.mesh);
    });

    test('cloud becomes available when backend reachable', () {
      monitor.setNetwork(true);
      monitor.setCloud(true);
      expect(coordinator.isCloudAvailable, isTrue);
      expect(coordinator.activeRing, Ring.cloud);
    });

    test('degrades to mesh when cloud drops', () {
      monitor.setNetwork(true);
      monitor.setCloud(true);
      expect(coordinator.activeRing, Ring.cloud);

      monitor.setCloud(false);
      expect(coordinator.activeRing, Ring.mesh);
      expect(coordinator.isCloudAvailable, isFalse);
    });

    test('degrades to edge when network drops completely', () {
      monitor.setNetwork(true);
      monitor.setCloud(true);
      expect(coordinator.activeRing, Ring.cloud);

      monitor.setNetwork(false);
      monitor.setCloud(false);
      expect(coordinator.activeRing, Ring.edge);
    });

    test('notifies listeners on connectivity change', () {
      int callCount = 0;
      coordinator.addListener(() => callCount++);

      monitor.setNetwork(true);
      expect(callCount, greaterThan(0));
    });

    test('ring instances are accessible', () {
      expect(coordinator.edgeRing, isA<EdgeRing>());
      expect(coordinator.meshRing, isA<MeshRing>());
      expect(coordinator.cloudRing, isA<CloudRing>());
    });

    test('state availableRings reflects coordinator state', () {
      expect(coordinator.state.availableRings, {Ring.edge});

      monitor.setNetwork(true);
      expect(coordinator.state.availableRings, {Ring.edge, Ring.mesh});

      monitor.setCloud(true);
      expect(
        coordinator.state.availableRings,
        {Ring.edge, Ring.mesh, Ring.cloud},
      );
    });

    test('full lifecycle: connect → degrade → reconnect', () {
      // Start offline
      expect(coordinator.activeRing, Ring.edge);

      // Network comes up
      monitor.setNetwork(true);
      expect(coordinator.activeRing, Ring.mesh);

      // Cloud becomes reachable
      monitor.setCloud(true);
      expect(coordinator.activeRing, Ring.cloud);

      // Cloud drops (server maintenance)
      monitor.setCloud(false);
      expect(coordinator.activeRing, Ring.mesh);

      // Network drops entirely (tunnel/airplane mode)
      monitor.setNetwork(false);
      expect(coordinator.activeRing, Ring.edge);

      // Reconnect
      monitor.setNetwork(true);
      monitor.setCloud(true);
      expect(coordinator.activeRing, Ring.cloud);
    });
  });
}
