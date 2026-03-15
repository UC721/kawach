import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// A space-efficient probabilistic data structure used by the KAWACH mesh
/// protocol to deduplicate messages.
///
/// Each message's [deduplicationKey] (`messageId:timestamp`) is inserted into
/// the filter. Before relaying, the protocol checks [mightContain] — if the
/// key is probably present the message is dropped as a duplicate.
///
/// The filter is periodically [reset] (or replaced) to evict stale entries
/// whose TTL has long passed, keeping the false-positive rate low.
class BloomFilter {
  /// Number of bits in the underlying bit-array.
  final int size;

  /// Number of independent hash functions applied to each key.
  final int hashCount;

  /// The bit-array backing this filter.
  final Uint8List _bits;

  /// Running count of items added (informational; not exact after reset).
  int _count = 0;

  /// Creates a bloom filter with the given [size] (in bits) and [hashCount].
  ///
  /// Typical defaults for ≤ 10 000 messages with < 1 % false-positive rate:
  /// `size = 95 851`, `hashCount = 7`.
  BloomFilter({this.size = 95851, this.hashCount = 7})
      : _bits = Uint8List((size + 7) ~/ 8);

  /// Creates a bloom filter sized for the expected [itemCount] with the
  /// desired [falsePositiveRate].
  factory BloomFilter.optimal({
    required int itemCount,
    double falsePositiveRate = 0.01,
  }) {
    // m = -(n * ln(p)) / (ln(2)^2)
    final m = (-(itemCount * math.log(falsePositiveRate)) /
            (math.ln2 * math.ln2))
        .ceil();
    // k = (m / n) * ln(2)
    final k = ((m / itemCount) * math.ln2).round().clamp(1, 30);
    return BloomFilter(size: m, hashCount: k);
  }

  // ── Public API ──────────────────────────────────────────────────

  /// Add [item] to the filter.
  void add(String item) {
    for (final index in _hashIndices(item)) {
      _setBit(index);
    }
    _count++;
  }

  /// Returns `true` if [item] **might** have been added previously.
  ///
  /// False positives are possible; false negatives are not.
  bool mightContain(String item) {
    for (final index in _hashIndices(item)) {
      if (!_getBit(index)) return false;
    }
    return true;
  }

  /// Clears every bit, effectively creating a fresh filter.
  void reset() {
    _bits.fillRange(0, _bits.length, 0);
    _count = 0;
  }

  /// Approximate number of items added since the last [reset].
  int get count => _count;

  // ── Internal helpers ────────────────────────────────────────────

  /// Generates [hashCount] bit indices for [item] using double-hashing
  /// (Kirsch–Mitzenmacker optimization) over a single SHA-256 digest.
  List<int> _hashIndices(String item) {
    final digest = sha256.convert(utf8.encode(item)).bytes;
    // Use first 4 bytes as h1, next 4 bytes as h2.
    final h1 = _bytesToInt(digest, 0);
    final h2 = _bytesToInt(digest, 4);

    return List<int>.generate(hashCount, (i) {
      final combined = (h1 + i * h2) % size;
      return combined < 0 ? combined + size : combined;
    });
  }

  /// Reads 4 bytes from [bytes] starting at [offset] as an unsigned int.
  static int _bytesToInt(List<int> bytes, int offset) {
    return (bytes[offset] << 24) |
        (bytes[offset + 1] << 16) |
        (bytes[offset + 2] << 8) |
        bytes[offset + 3];
  }

  void _setBit(int index) {
    _bits[index >> 3] |= (1 << (index & 7));
  }

  bool _getBit(int index) {
    return (_bits[index >> 3] & (1 << (index & 7))) != 0;
  }
}
