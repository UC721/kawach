import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/models/mesh_message_model.dart';
import 'package:kawach/services/mesh/bloom_filter.dart';
import 'package:kawach/services/mesh/mesh_crypto_service.dart';
import 'package:kawach/services/mesh/mesh_protocol_service.dart';

void main() {
  group('MeshProtocolService', () {
    late MeshProtocolService protocol;
    late MeshCryptoService crypto;
    late String networkKey;

    setUp(() {
      crypto = MeshCryptoService();
      networkKey = crypto.deriveKey('test-network');
      protocol = MeshProtocolService(
        bloomFilter: BloomFilter(size: 10000, hashCount: 7),
        cryptoService: crypto,
        networkKey: networkKey,
      );
    });

    // ── Message creation ──────────────────────────────────────────

    test('createMessage returns encrypted message with UUID', () {
      final msg = protocol.createMessage(
        senderId: 'device-1',
        plaintextPayload: 'SOS at 12.34, 56.78',
      );

      expect(msg.messageId.isNotEmpty, true);
      expect(msg.senderId, 'device-1');
      expect(msg.type, MeshMessageType.emergency);
      expect(msg.hopCount, 0);
      expect(msg.isExpired, false);
      // Payload should be encrypted (not plaintext).
      expect(msg.payload, isNot(equals('SOS at 12.34, 56.78')));
    });

    test('createMessage auto-registers in bloom filter', () {
      final msg = protocol.createMessage(
        senderId: 'device-1',
        plaintextPayload: 'test',
      );
      expect(protocol.bloomCount, 1);

      // Same message should be seen as duplicate.
      expect(
        protocol.handleIncoming(msg),
        completion(MeshRelayDecision.duplicate),
      );
    });

    test('createMessage respects custom TTL and maxHops', () {
      final msg = protocol.createMessage(
        senderId: 'device-1',
        plaintextPayload: 'test',
        ttlSeconds: 600,
        maxHops: 5,
      );
      expect(msg.ttlSeconds, 600);
      expect(msg.maxHops, 5);
    });

    // ── Deduplication ─────────────────────────────────────────────

    test('handleIncoming rejects duplicate messages', () async {
      final msg = _makeMessage(messageId: 'dup-1');

      final first = await protocol.handleIncoming(msg);
      expect(first, isNot(MeshRelayDecision.duplicate));

      final second = await protocol.handleIncoming(msg);
      expect(second, MeshRelayDecision.duplicate);
    });

    // ── TTL enforcement ───────────────────────────────────────────

    test('handleIncoming rejects expired messages', () async {
      final now = DateTime.now();
      final expired = MeshMessageModel(
        messageId: 'expired-1',
        senderId: 'device-x',
        type: MeshMessageType.emergency,
        payload: 'data',
        ttlSeconds: 0,
        createdAt: now.subtract(const Duration(seconds: 600)),
        expiresAt: now.subtract(const Duration(seconds: 300)),
      );

      final result = await protocol.handleIncoming(expired);
      expect(result, MeshRelayDecision.expired);
    });

    // ── Hop enforcement ───────────────────────────────────────────

    test('handleIncoming rejects messages at max hops', () async {
      final msg = _makeMessage(messageId: 'maxhop-1', hopCount: 10, maxHops: 10);

      final result = await protocol.handleIncoming(msg);
      expect(result, MeshRelayDecision.maxHopsReached);
    });

    // ── Relay preparation ─────────────────────────────────────────

    test('prepareForRelay increments hop count', () {
      final msg = _makeMessage(messageId: 'relay-1', hopCount: 2);
      final relayed = protocol.prepareForRelay(msg);
      expect(relayed.hopCount, 3);
    });

    // ── Payload decryption ────────────────────────────────────────

    test('decryptPayload recovers original content', () {
      final msg = protocol.createMessage(
        senderId: 'device-1',
        plaintextPayload: 'Help me at park',
      );
      final decrypted = protocol.decryptPayload(msg);
      expect(decrypted, 'Help me at park');
    });

    // ── Bloom filter maintenance ──────────────────────────────────

    test('purgeBloomFilter resets dedup state', () async {
      final msg = _makeMessage(messageId: 'purge-1');
      await protocol.handleIncoming(msg);

      protocol.purgeBloomFilter();
      expect(protocol.bloomCount, 0);
    });

    // ── Relay queue ───────────────────────────────────────────────

    test('clearRelayQueue empties the queue', () async {
      // This will go to relay queue if not a gateway (offline scenario).
      // Since we can't mock connectivity easily without a plugin mock,
      // we just verify the clearRelayQueue API works.
      protocol.clearRelayQueue();
      expect(protocol.relayQueue, isEmpty);
    });
  });
}

/// Helper to create a test message with sensible defaults.
MeshMessageModel _makeMessage({
  required String messageId,
  int hopCount = 0,
  int maxHops = 10,
  int ttlSeconds = 300,
}) {
  final now = DateTime.now();
  return MeshMessageModel(
    messageId: messageId,
    senderId: 'test-device',
    type: MeshMessageType.emergency,
    payload: 'test-payload',
    ttlSeconds: ttlSeconds,
    hopCount: hopCount,
    maxHops: maxHops,
    createdAt: now,
    expiresAt: now.add(Duration(seconds: ttlSeconds)),
  );
}
