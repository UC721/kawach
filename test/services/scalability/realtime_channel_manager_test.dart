import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/models/scalability_config_model.dart';
import 'package:kawach/services/scalability/realtime_channel_manager.dart';

void main() {
  group('RealtimeChannelManager', () {
    late RealtimeChannelManager manager;

    setUp(() {
      manager = RealtimeChannelManager(
        config: const ScalabilityConfig(maxRealtimeChannels: 3),
      );
    });

    tearDown(() => manager.dispose());

    test('subscribe adds a channel', () {
      expect(manager.subscribe('emergency:user1'), isTrue);
      expect(manager.activeChannels, 1);
      expect(manager.isSubscribed('emergency:user1'), isTrue);
    });

    test('rejects subscription when at capacity', () {
      manager.subscribe('a');
      manager.subscribe('b');
      manager.subscribe('c');
      expect(manager.subscribe('d'), isFalse);
      expect(manager.activeChannels, 3);
    });

    test('re-subscribing an existing channel succeeds', () {
      manager.subscribe('a');
      manager.subscribe('b');
      manager.subscribe('c');
      expect(manager.subscribe('a'), isTrue); // already tracked
    });

    test('unsubscribe removes a channel', () {
      manager.subscribe('a');
      manager.unsubscribe('a');
      expect(manager.isSubscribed('a'), isFalse);
      expect(manager.activeChannels, 0);
    });

    test('markDisconnected updates connected count', () {
      manager.subscribe('a');
      manager.subscribe('b');
      manager.markDisconnected('a');
      expect(manager.connectedChannels, 1);
    });

    test('reconnectDisconnected re-marks channels as connected', () {
      manager.subscribe('a');
      manager.subscribe('b');
      manager.markDisconnected('a');
      manager.markDisconnected('b');
      final reconnected = manager.reconnectDisconnected();
      expect(reconnected, containsAll(['a', 'b']));
      expect(manager.connectedChannels, 2);
    });

    test('channelNames returns all tracked names', () {
      manager.subscribe('x');
      manager.subscribe('y');
      expect(manager.channelNames, containsAll(['x', 'y']));
    });

    test('isAtCapacity reflects the limit', () {
      manager.subscribe('a');
      manager.subscribe('b');
      expect(manager.isAtCapacity, isFalse);
      manager.subscribe('c');
      expect(manager.isAtCapacity, isTrue);
    });
  });
}
