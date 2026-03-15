import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../models/mesh_message_model.dart';
import '../../utils/constants.dart';
import 'bloom_filter.dart';
import 'mesh_crypto_service.dart';

/// Result returned by [MeshProtocolService.handleIncoming].
enum MeshRelayDecision {
  /// Message was relayed to the next hop.
  relayed,

  /// Message was a duplicate and dropped.
  duplicate,

  /// Message exceeded its TTL and was dropped.
  expired,

  /// Message reached its maximum hop count and was dropped.
  maxHopsReached,

  /// This device is a gateway; the message was delivered upstream.
  deliveredToGateway,
}

/// Orchestrates the KAWACH mesh emergency network protocol.
///
/// Responsibilities:
/// * **Create** encrypted mesh messages with UUID + TTL.
/// * **Deduplicate** incoming messages via a bloom filter keyed on
///   `messageId:timestamp`.
/// * **Relay** valid messages hop-by-hop, decrementing TTL and incrementing
///   the hop counter.
/// * **Detect** whether the current device is an internet-connected
///   *gateway*, in which case the message is delivered upstream instead of
///   being relayed further.
class MeshProtocolService extends ChangeNotifier {
  MeshProtocolService({
    BloomFilter? bloomFilter,
    MeshCryptoService? cryptoService,
    Connectivity? connectivity,
    String? networkKey,
  })  : _bloom = bloomFilter ??
            BloomFilter.optimal(
              itemCount: MeshDefaults.bloomExpectedItems,
              falsePositiveRate: MeshDefaults.bloomFalsePositiveRate,
            ),
        _crypto = cryptoService ?? MeshCryptoService(),
        _connectivity = connectivity ?? Connectivity(),
        _networkKey = networkKey ?? MeshDefaults.fallbackNetworkKeyHex;

  final BloomFilter _bloom;
  final MeshCryptoService _crypto;
  final Connectivity _connectivity;
  final Uuid _uuid = const Uuid();

  /// Hex-encoded shared network encryption key.
  final String _networkKey;

  /// Messages that have been accepted and are queued for relay.
  final List<MeshMessageModel> _relayQueue = [];

  /// Messages delivered to the gateway for upstream sync.
  final List<MeshMessageModel> _deliveredMessages = [];

  List<MeshMessageModel> get relayQueue => List.unmodifiable(_relayQueue);
  List<MeshMessageModel> get deliveredMessages =>
      List.unmodifiable(_deliveredMessages);

  // ── Message creation ────────────────────────────────────────────

  /// Creates a new encrypted mesh message ready for broadcast.
  MeshMessageModel createMessage({
    required String senderId,
    required String plaintextPayload,
    MeshMessageType type = MeshMessageType.emergency,
    int ttlSeconds = MeshDefaults.ttlSeconds,
    int maxHops = MeshDefaults.maxHops,
  }) {
    final now = DateTime.now();
    final encrypted = _crypto.encrypt(plaintextPayload, _networkKey);

    final message = MeshMessageModel(
      messageId: _uuid.v4(),
      senderId: senderId,
      type: type,
      payload: encrypted,
      ttlSeconds: ttlSeconds,
      hopCount: 0,
      maxHops: maxHops,
      createdAt: now,
      expiresAt: now.add(Duration(seconds: ttlSeconds)),
    );

    // Mark as seen so the originator never processes its own message.
    _bloom.add(message.deduplicationKey);

    return message;
  }

  // ── Incoming message handling ───────────────────────────────────

  /// Processes an incoming mesh message and returns the relay decision.
  ///
  /// 1. Check bloom filter for duplicates.
  /// 2. Verify TTL and hop budget.
  /// 3. If this device has internet → deliver upstream (gateway).
  /// 4. Otherwise → prepare for relay (decrement TTL, increment hop).
  Future<MeshRelayDecision> handleIncoming(MeshMessageModel message) async {
    // ── Deduplication ──────────────────────────────────────────
    if (_bloom.mightContain(message.deduplicationKey)) {
      return MeshRelayDecision.duplicate;
    }

    // ── TTL check ──────────────────────────────────────────────
    if (message.isExpired) {
      return MeshRelayDecision.expired;
    }

    // ── Hop check ──────────────────────────────────────────────
    if (message.isMaxHopsReached) {
      return MeshRelayDecision.maxHopsReached;
    }

    // Mark as seen *before* any relay or delivery.
    _bloom.add(message.deduplicationKey);

    // ── Gateway check ──────────────────────────────────────────
    if (await isGateway()) {
      _deliveredMessages.add(message);
      notifyListeners();
      return MeshRelayDecision.deliveredToGateway;
    }

    // ── Prepare relay ──────────────────────────────────────────
    final relayMessage = prepareForRelay(message);
    _relayQueue.add(relayMessage);
    notifyListeners();
    return MeshRelayDecision.relayed;
  }

  // ── Relay preparation ───────────────────────────────────────────

  /// Decrements TTL (by elapsed seconds) and increments the hop counter.
  MeshMessageModel prepareForRelay(MeshMessageModel message) {
    final elapsed =
        DateTime.now().difference(message.createdAt).inSeconds;
    final remainingTtl = message.ttlSeconds - elapsed;

    return message.copyWith(
      ttlSeconds: remainingTtl > 0 ? remainingTtl : 0,
      hopCount: message.hopCount + 1,
    );
  }

  // ── Payload decryption (for gateway / final recipient) ──────────

  /// Decrypts the payload of a delivered message.
  String decryptPayload(MeshMessageModel message) {
    return _crypto.decrypt(message.payload, _networkKey);
  }

  // ── Gateway detection ───────────────────────────────────────────

  /// Returns `true` when this device has internet access and can act as
  /// a gateway to sync mesh messages upstream.
  Future<bool> isGateway() async {
    final result = await _connectivity.checkConnectivity();
    return result.any((r) =>
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.mobile ||
        r == ConnectivityResult.ethernet);
  }

  // ── Bloom filter maintenance ────────────────────────────────────

  /// Resets the bloom filter — should be called periodically (e.g. every
  /// `meshBloomResetInterval`) to keep the false-positive rate low.
  void purgeBloomFilter() {
    _bloom.reset();
  }

  /// Number of keys tracked by the current bloom filter generation.
  int get bloomCount => _bloom.count;

  /// Clears the relay queue (e.g. after successful broadcast).
  void clearRelayQueue() {
    _relayQueue.clear();
    notifyListeners();
  }
}
