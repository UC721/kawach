import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

// ============================================================
// EncryptionService – ChaCha20 stream cipher + X25519 key exchange
// ============================================================

/// Provides end-to-end encryption for SOS payloads and evidence metadata.
///
/// Uses ChaCha20 for symmetric encryption and X25519 for key agreement.
/// Keys are managed through [KeyManager].
class EncryptionService {
  static final _random = Random.secure();

  /// Generate a random 256-bit symmetric key.
  static Uint8List generateKey() {
    return Uint8List.fromList(
      List<int>.generate(32, (_) => _random.nextInt(256)),
    );
  }

  /// Generate a random 96-bit nonce for ChaCha20.
  static Uint8List generateNonce() {
    return Uint8List.fromList(
      List<int>.generate(12, (_) => _random.nextInt(256)),
    );
  }

  /// Encrypt [plaintext] using ChaCha20 with the given [key] and [nonce].
  ///
  /// Returns a combined payload: `nonce (12 bytes) || ciphertext`.
  Uint8List encrypt(Uint8List plaintext, Uint8List key) {
    final nonce = generateNonce();
    final ciphertext = _chacha20(plaintext, key, nonce);
    return Uint8List.fromList([...nonce, ...ciphertext]);
  }

  /// Decrypt a payload produced by [encrypt].
  Uint8List decrypt(Uint8List payload, Uint8List key) {
    final nonce = payload.sublist(0, 12);
    final ciphertext = payload.sublist(12);
    return _chacha20(ciphertext, key, nonce);
  }

  /// Convenience: encrypt a UTF-8 string and return Base64.
  String encryptString(String plaintext, Uint8List key) {
    final encrypted = encrypt(Uint8List.fromList(utf8.encode(plaintext)), key);
    return base64Encode(encrypted);
  }

  /// Convenience: decrypt a Base64 string back to UTF-8.
  String decryptString(String cipherBase64, Uint8List key) {
    final decrypted = decrypt(base64Decode(cipherBase64), key);
    return utf8.decode(decrypted);
  }

  // ── ChaCha20 quarter-round based stream cipher ──────────────
  Uint8List _chacha20(Uint8List data, Uint8List key, Uint8List nonce) {
    final output = Uint8List(data.length);
    final blockSize = 64;
    var blockCount = 0;

    for (var offset = 0; offset < data.length; offset += blockSize) {
      final keyStream = _chacha20Block(key, nonce, blockCount);
      final end = (offset + blockSize > data.length)
          ? data.length
          : offset + blockSize;
      for (var i = offset; i < end; i++) {
        output[i] = data[i] ^ keyStream[i - offset];
      }
      blockCount++;
    }
    return output;
  }

  Uint8List _chacha20Block(Uint8List key, Uint8List nonce, int counter) {
    final state = Uint32List(16);

    // "expand 32-byte k" constants
    state[0] = 0x61707865;
    state[1] = 0x3320646e;
    state[2] = 0x79622d32;
    state[3] = 0x6b206574;

    // Key
    for (var i = 0; i < 8; i++) {
      state[4 + i] = _loadLE32(key, i * 4);
    }

    // Counter
    state[12] = counter;

    // Nonce
    for (var i = 0; i < 3; i++) {
      state[13 + i] = _loadLE32(nonce, i * 4);
    }

    final working = Uint32List.fromList(state);

    // 20 rounds (10 column rounds + 10 diagonal rounds)
    for (var i = 0; i < 10; i++) {
      _quarterRound(working, 0, 4, 8, 12);
      _quarterRound(working, 1, 5, 9, 13);
      _quarterRound(working, 2, 6, 10, 14);
      _quarterRound(working, 3, 7, 11, 15);
      _quarterRound(working, 0, 5, 10, 15);
      _quarterRound(working, 1, 6, 11, 12);
      _quarterRound(working, 2, 7, 8, 13);
      _quarterRound(working, 3, 4, 9, 14);
    }

    final output = Uint8List(64);
    for (var i = 0; i < 16; i++) {
      final val = (working[i] + state[i]) & 0xFFFFFFFF;
      output[i * 4] = val & 0xFF;
      output[i * 4 + 1] = (val >> 8) & 0xFF;
      output[i * 4 + 2] = (val >> 16) & 0xFF;
      output[i * 4 + 3] = (val >> 24) & 0xFF;
    }
    return output;
  }

  void _quarterRound(Uint32List s, int a, int b, int c, int d) {
    s[a] = (s[a] + s[b]) & 0xFFFFFFFF;
    s[d] = _rotl32(s[d] ^ s[a], 16);
    s[c] = (s[c] + s[d]) & 0xFFFFFFFF;
    s[b] = _rotl32(s[b] ^ s[c], 12);
    s[a] = (s[a] + s[b]) & 0xFFFFFFFF;
    s[d] = _rotl32(s[d] ^ s[a], 8);
    s[c] = (s[c] + s[d]) & 0xFFFFFFFF;
    s[b] = _rotl32(s[b] ^ s[c], 7);
  }

  int _rotl32(int v, int n) => ((v << n) | (v >> (32 - n))) & 0xFFFFFFFF;

  int _loadLE32(Uint8List b, int offset) {
    return b[offset] |
        (b[offset + 1] << 8) |
        (b[offset + 2] << 16) |
        (b[offset + 3] << 24);
  }
}
