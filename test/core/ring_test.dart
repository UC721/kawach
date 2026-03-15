import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/core/ring.dart';

void main() {
  group('Ring enum', () {
    test('has three values', () {
      expect(Ring.values.length, 3);
      expect(Ring.values, contains(Ring.edge));
      expect(Ring.values, contains(Ring.mesh));
      expect(Ring.values, contains(Ring.cloud));
    });
  });

  group('RingState', () {
    test('defaults: edge available, mesh/cloud unavailable', () {
      final state = RingState(updatedAt: DateTime.now());
      expect(state.edgeAvailable, isTrue);
      expect(state.meshAvailable, isFalse);
      expect(state.cloudAvailable, isFalse);
    });

    test('activeRing returns edge when only edge available', () {
      final state = RingState(updatedAt: DateTime.now());
      expect(state.activeRing, Ring.edge);
    });

    test('activeRing returns mesh when mesh available but not cloud', () {
      final state = RingState(
        meshAvailable: true,
        updatedAt: DateTime.now(),
      );
      expect(state.activeRing, Ring.mesh);
    });

    test('activeRing returns cloud when cloud available', () {
      final state = RingState(
        meshAvailable: true,
        cloudAvailable: true,
        updatedAt: DateTime.now(),
      );
      expect(state.activeRing, Ring.cloud);
    });

    test('activeRing returns cloud even if mesh is unavailable', () {
      final state = RingState(
        meshAvailable: false,
        cloudAvailable: true,
        updatedAt: DateTime.now(),
      );
      expect(state.activeRing, Ring.cloud);
    });

    test('availableRings includes only available rings', () {
      final edgeOnly = RingState(updatedAt: DateTime.now());
      expect(edgeOnly.availableRings, {Ring.edge});

      final meshAndEdge = RingState(
        meshAvailable: true,
        updatedAt: DateTime.now(),
      );
      expect(meshAndEdge.availableRings, {Ring.edge, Ring.mesh});

      final allRings = RingState(
        meshAvailable: true,
        cloudAvailable: true,
        updatedAt: DateTime.now(),
      );
      expect(allRings.availableRings, {Ring.edge, Ring.mesh, Ring.cloud});
    });

    test('hasMeshOrCloud is true when mesh or cloud available', () {
      final edgeOnly = RingState(updatedAt: DateTime.now());
      expect(edgeOnly.hasMeshOrCloud, isFalse);

      final withMesh = RingState(
        meshAvailable: true,
        updatedAt: DateTime.now(),
      );
      expect(withMesh.hasMeshOrCloud, isTrue);

      final withCloud = RingState(
        cloudAvailable: true,
        updatedAt: DateTime.now(),
      );
      expect(withCloud.hasMeshOrCloud, isTrue);
    });

    test('copyWith creates new state with updated fields', () {
      final original = RingState(updatedAt: DateTime(2024, 1, 1));

      final upgraded = original.copyWith(meshAvailable: true);
      expect(upgraded.edgeAvailable, isTrue);
      expect(upgraded.meshAvailable, isTrue);
      expect(upgraded.cloudAvailable, isFalse);
      // Original is unchanged
      expect(original.meshAvailable, isFalse);
    });

    test('copyWith preserves unset fields', () {
      final state = RingState(
        meshAvailable: true,
        cloudAvailable: true,
        updatedAt: DateTime(2024, 1, 1),
      );

      final updated = state.copyWith(cloudAvailable: false);
      expect(updated.edgeAvailable, isTrue);
      expect(updated.meshAvailable, isTrue);
      expect(updated.cloudAvailable, isFalse);
    });

    test('toString includes all fields', () {
      final state = RingState(
        meshAvailable: true,
        cloudAvailable: true,
        updatedAt: DateTime.now(),
      );
      final str = state.toString();
      expect(str, contains('edge: true'));
      expect(str, contains('mesh: true'));
      expect(str, contains('cloud: true'));
      expect(str, contains('active: cloud'));
    });

    test('degradation: all rings → mesh only → edge only', () {
      var state = RingState(
        meshAvailable: true,
        cloudAvailable: true,
        updatedAt: DateTime.now(),
      );
      expect(state.activeRing, Ring.cloud);
      expect(state.availableRings.length, 3);

      // Cloud goes down
      state = state.copyWith(cloudAvailable: false);
      expect(state.activeRing, Ring.mesh);
      expect(state.availableRings.length, 2);

      // Mesh goes down
      state = state.copyWith(meshAvailable: false);
      expect(state.activeRing, Ring.edge);
      expect(state.availableRings.length, 1);
      expect(state.availableRings, {Ring.edge});
    });
  });
}
