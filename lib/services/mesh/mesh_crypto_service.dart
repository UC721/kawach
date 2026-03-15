import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart' as pc;

/// Provides AES-256-CBC encryption, HMAC-SHA256 signing, and key derivation
/// for the KAWACH mesh protocol.
///
/// Every mesh message payload is encrypted before broadcast and verified
/// via HMAC upon receipt. A shared network key is derived once from a
/// passphrase using PBKDF2.
class MeshCryptoService {
  static const int _ivLength = 16; // AES block size
  static const int _keyLength = 32; // 256 bits
  static const int _pbkdf2Iterations = 100000;

  final Random _random = Random.secure();

  // ── Key derivation ──────────────────────────────────────────────

  /// Derives a 256-bit key from [passphrase] using PBKDF2-HMAC-SHA256.
  ///
  /// The returned key is hex-encoded for easy storage / transport.
  String deriveKey(String passphrase, {String? salt}) {
    final saltBytes =
        Uint8List.fromList(utf8.encode(salt ?? 'kawach-mesh-salt'));
    final pbkdf2 = pc.PBKDF2KeyDerivator(pc.HMac(pc.SHA256Digest(), 64))
      ..init(pc.Pbkdf2Parameters(saltBytes, _pbkdf2Iterations, _keyLength));
    final key = pbkdf2.process(Uint8List.fromList(utf8.encode(passphrase)));
    return _bytesToHex(key);
  }

  // ── Encryption ──────────────────────────────────────────────────

  /// Encrypts [plaintext] with AES-256-CBC using [hexKey].
  ///
  /// Returns a Base-64 string of `IV || ciphertext`.
  String encrypt(String plaintext, String hexKey) {
    final keyBytes = _hexToBytes(hexKey);
    final iv = _generateIv();
    final plaintextBytes = Uint8List.fromList(utf8.encode(plaintext));

    final cipher = pc.PaddedBlockCipher('AES/CBC/PKCS7')
      ..init(
        true,
        pc.PaddedBlockCipherParameters<pc.CipherParameters,
            pc.CipherParameters>(
          pc.ParametersWithIV<pc.KeyParameter>(
              pc.KeyParameter(keyBytes), iv),
          null,
        ),
      );

    final encrypted = cipher.process(plaintextBytes);

    // Prepend IV so the receiver can decrypt without out-of-band IV exchange.
    final combined = Uint8List(iv.length + encrypted.length)
      ..setRange(0, iv.length, iv)
      ..setRange(iv.length, iv.length + encrypted.length, encrypted);

    return base64.encode(combined);
  }

  /// Decrypts a Base-64 [ciphertext] produced by [encrypt].
  String decrypt(String ciphertext, String hexKey) {
    final keyBytes = _hexToBytes(hexKey);
    final combined = base64.decode(ciphertext);

    final iv = Uint8List.sublistView(combined, 0, _ivLength);
    final encrypted = Uint8List.sublistView(combined, _ivLength);

    final cipher = pc.PaddedBlockCipher('AES/CBC/PKCS7')
      ..init(
        false,
        pc.PaddedBlockCipherParameters<pc.CipherParameters,
            pc.CipherParameters>(
          pc.ParametersWithIV<pc.KeyParameter>(
              pc.KeyParameter(keyBytes), iv),
          null,
        ),
      );

    final decrypted = cipher.process(encrypted);
    return utf8.decode(decrypted);
  }

  // ── HMAC signing ────────────────────────────────────────────────

  /// Signs [data] with HMAC-SHA256 using [hexKey].
  String sign(String data, String hexKey) {
    final keyBytes = _hexToBytes(hexKey);
    final hmacSha256 = Hmac(sha256, keyBytes);
    return hmacSha256.convert(utf8.encode(data)).toString();
  }

  /// Verifies an HMAC-SHA256 [signature] for [data].
  bool verify(String data, String signature, String hexKey) {
    return sign(data, hexKey) == signature;
  }

  // ── Internal helpers ────────────────────────────────────────────

  Uint8List _generateIv() {
    final iv = Uint8List(_ivLength);
    for (int i = 0; i < _ivLength; i++) {
      iv[i] = _random.nextInt(256);
    }
    return iv;
  }

  static Uint8List _hexToBytes(String hex) {
    final length = hex.length;
    final bytes = Uint8List(length ~/ 2);
    for (int i = 0; i < length; i += 2) {
      bytes[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return bytes;
  }

  static String _bytesToHex(Uint8List bytes) {
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
