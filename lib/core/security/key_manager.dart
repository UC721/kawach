import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages cryptographic keys for the KAWACH security layer.
///
/// KEY HIERARCHY
/// - Master key: device-bound, stored in Android Keystore / iOS Secure Enclave
///   via [FlutterSecureStorage].
/// - Session keys: X25519 ECDH — derived per-alert, ephemeral.
/// - Evidence keys: AES-256-GCM, wrapped by master key, stored in Supabase
///   Vault.
class KeyManager {
  KeyManager({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _secureStorage;

  static const _masterKeyAlias = 'kawach_master_key';
  static const _signingKeyAlias = 'kawach_signing_key';
  static const _evidenceKeyInfoBytes = 'kawach-evidence-v1';

  // ---------------------------------------------------------------------------
  // Master key
  // ---------------------------------------------------------------------------

  /// Returns the 256-bit master key, creating one on first use.
  Future<SecretKey> getMasterKey() async {
    final stored = await _secureStorage.read(key: _masterKeyAlias);
    if (stored != null) {
      return SecretKey(_hexToBytes(stored));
    }
    final algorithm = AesGcm.with256bits();
    final masterKey = await algorithm.newSecretKey();
    final bytes = await masterKey.extractBytes();
    await _secureStorage.write(key: _masterKeyAlias, value: _bytesToHex(bytes));
    return masterKey;
  }

  // ---------------------------------------------------------------------------
  // Evidence key derivation
  // ---------------------------------------------------------------------------

  /// Derives a per-evidence AES-256-GCM key from the master key using HKDF.
  Future<SecretKey> deriveEvidenceKey() async {
    final masterKey = await getMasterKey();
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    return hkdf.deriveKey(
      secretKey: masterKey,
      nonce: Uint8List(0), // empty salt
      info: utf8.encode(_evidenceKeyInfoBytes),
    );
  }

  // ---------------------------------------------------------------------------
  // Ed25519 signing key
  // ---------------------------------------------------------------------------

  /// Persisted Ed25519 private key for mesh message signing.
  SimpleKeyPair? _signingKeyPair;

  Future<SimpleKeyPair> getSigningKeyPair() async {
    if (_signingKeyPair != null) return _signingKeyPair!;

    final stored = await _secureStorage.read(key: _signingKeyAlias);
    if (stored != null) {
      final privateBytes = _hexToBytes(stored);
      final algorithm = Ed25519();
      final keyPair = await algorithm.newKeyPairFromSeed(privateBytes);
      _signingKeyPair = keyPair as SimpleKeyPair;
      return _signingKeyPair!;
    }

    final algorithm = Ed25519();
    final keyPair = await algorithm.newKeyPair();
    _signingKeyPair = keyPair as SimpleKeyPair;
    final seed = await _signingKeyPair!.extractPrivateKeyBytes();
    await _secureStorage.write(key: _signingKeyAlias, value: _bytesToHex(seed));
    return _signingKeyPair!;
  }

  /// The raw private key bytes for Ed25519 signing.
  Future<List<int>> get signingPrivateKeyBytes async {
    final keyPair = await getSigningKeyPair();
    return keyPair.extractPrivateKeyBytes();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static Uint8List _hexToBytes(String hex) {
    final length = hex.length;
    final bytes = Uint8List(length ~/ 2);
    for (var i = 0; i < length; i += 2) {
      bytes[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return bytes;
  }

  static String _bytesToHex(List<int> bytes) =>
      bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  static Uint8List _utf8Bytes(String s) => Uint8List.fromList(utf8.encode(s));
}
