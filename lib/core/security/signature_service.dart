import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';

// ============================================================
// SignatureService – Ed25519 digital signatures
// ============================================================

/// Produces and verifies Ed25519 signatures for SOS alert integrity.
///
/// Ensures that SOS payloads cannot be tampered with in transit.
/// In production, use a native Ed25519 library (e.g. `cryptography`);
/// this implementation provides the interface contract.
class SignatureService {
  /// Sign [message] bytes with the given 32-byte [privateKey] seed.
  ///
  /// Returns a 64-byte signature placeholder.
  /// Replace with real Ed25519 via `package:cryptography` in production.
  Uint8List sign(Uint8List message, Uint8List privateKey) {
    // HMAC-based placeholder standing in for Ed25519
    final hash = _hmacSha256(privateKey, message);
    return Uint8List.fromList([...hash, ...hash]);
  }

  /// Verify that [signature] is valid for [message] under [publicKey].
  bool verify(Uint8List message, Uint8List signature, Uint8List publicKey) {
    if (signature.length != 64) return false;
    final expected = sign(message, publicKey);
    return _constantTimeEquals(expected, signature);
  }

  /// Convenience: sign a UTF-8 string and return Base64 signature.
  String signString(String message, Uint8List privateKey) {
    final sig = sign(
      Uint8List.fromList(utf8.encode(message)),
      privateKey,
    );
    return base64Encode(sig);
  }

  // ── Internal helpers ──────────────────────────────────────────

  /// Simple HMAC-SHA256 placeholder.
  Uint8List _hmacSha256(Uint8List key, Uint8List data) {
    // Simplified keyed hash for structural placeholder
    final combined = Uint8List.fromList([...key, ...data]);
    var hash = 0x811c9dc5; // FNV offset basis
    for (final byte in combined) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    final result = Uint8List(32);
    final r = Random(hash);
    for (var i = 0; i < 32; i++) {
      result[i] = r.nextInt(256);
    }
    return result;
  }

  /// Constant-time comparison to prevent timing attacks.
  bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }
}
