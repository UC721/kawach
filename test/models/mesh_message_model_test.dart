import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/models/mesh_message_model.dart';

void main() {
  group('MeshMessageModel', () {
    late MeshMessageModel message;
    late DateTime now;

    setUp(() {
      now = DateTime.now();
      message = MeshMessageModel(
        messageId: 'test-uuid-1234',
        senderId: 'device-abc',
        type: MeshMessageType.emergency,
        payload: 'encrypted-payload',
        ttlSeconds: 300,
        hopCount: 0,
        maxHops: 10,
        createdAt: now,
        expiresAt: now.add(const Duration(seconds: 300)),
      );
    });

    test('creates message with correct defaults', () {
      expect(message.messageId, 'test-uuid-1234');
      expect(message.senderId, 'device-abc');
      expect(message.type, MeshMessageType.emergency);
      expect(message.payload, 'encrypted-payload');
      expect(message.ttlSeconds, 300);
      expect(message.hopCount, 0);
      expect(message.maxHops, 10);
    });

    test('isExpired returns false for fresh message', () {
      expect(message.isExpired, false);
    });

    test('isExpired returns true for expired message', () {
      final expired = MeshMessageModel(
        messageId: 'expired-msg',
        senderId: 'device-abc',
        type: MeshMessageType.emergency,
        payload: 'data',
        ttlSeconds: 0,
        createdAt: now.subtract(const Duration(seconds: 600)),
        expiresAt: now.subtract(const Duration(seconds: 300)),
      );
      expect(expired.isExpired, true);
    });

    test('isMaxHopsReached returns false when under budget', () {
      expect(message.isMaxHopsReached, false);
    });

    test('isMaxHopsReached returns true at max hops', () {
      final maxed = message.copyWith(hopCount: 10);
      expect(maxed.isMaxHopsReached, true);
    });

    test('deduplicationKey combines messageId and timestamp', () {
      final key = message.deduplicationKey;
      expect(key, contains('test-uuid-1234'));
      expect(key, contains(':'));
      expect(key, contains(now.millisecondsSinceEpoch.toString()));
    });

    test('toMap produces correct keys', () {
      final map = message.toMap();
      expect(map['message_id'], 'test-uuid-1234');
      expect(map['sender_id'], 'device-abc');
      expect(map['type'], 'emergency');
      expect(map['payload'], 'encrypted-payload');
      expect(map['ttl_seconds'], 300);
      expect(map['hop_count'], 0);
      expect(map['max_hops'], 10);
      expect(map.containsKey('created_at'), true);
      expect(map.containsKey('expires_at'), true);
    });

    test('fromMap round-trips correctly', () {
      final map = message.toMap();
      final restored = MeshMessageModel.fromMap(map);
      expect(restored.messageId, message.messageId);
      expect(restored.senderId, message.senderId);
      expect(restored.type, message.type);
      expect(restored.payload, message.payload);
      expect(restored.ttlSeconds, message.ttlSeconds);
      expect(restored.hopCount, message.hopCount);
      expect(restored.maxHops, message.maxHops);
    });

    test('copyWith preserves unchanged fields', () {
      final updated = message.copyWith(hopCount: 3, ttlSeconds: 200);
      expect(updated.hopCount, 3);
      expect(updated.ttlSeconds, 200);
      expect(updated.messageId, message.messageId);
      expect(updated.senderId, message.senderId);
      expect(updated.type, message.type);
      expect(updated.payload, message.payload);
    });

    test('toString contains key information', () {
      final str = message.toString();
      expect(str, contains('test-uuid-1234'));
      expect(str, contains('emergency'));
      expect(str, contains('0/10'));
    });

    test('all MeshMessageType values are serialisable', () {
      for (final type in MeshMessageType.values) {
        final msg = message.copyWith(type: type);
        final map = msg.toMap();
        final restored = MeshMessageModel.fromMap(map);
        expect(restored.type, type);
      }
    });
  });
}
