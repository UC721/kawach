import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages cryptographic keys for KAWACH.
///
/// * **Master key** — AES-256-GCM stored in Android Keystore / iOS Secure
///   Enclave via [FlutterSecureStorage].
/// * **Evidence keys** — Derived per-evidence via HKDF-SHA256 from the master
///   key (symmetric key stored in Supabase Vault in production).
/// * **Signing key** — Ed25519 key pair persisted in secure storage.
class KeyManager {
  static const _masterKeyAlias = 'kawach_master_key';
  static const _signingKeyAlias = 'kawach_signing_key';

  // FlutterSecureStorage automatically uses Android Keystore / iOS Keychain
  // (backed by Secure Enclave on supported devices).
  final FlutterSecureStorage _secureStorage;

  KeyManager({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  // ── Master key ───────────────────────────────────────────────

  /// Returns the 256-bit master key, creating one if it does not exist.
  Future<SecretKey> getMasterKey() async {
    final stored = await _secureStorage.read(key: _masterKeyAlias);
    if (stored != null) {
      return SecretKey(base64Decode(stored));
    }

    // Generate a new 256-bit key
    final key = await AesGcm.with256bits().newSecretKey();
    final bytes = await key.extractBytes();
    await _secureStorage.write(
      key: _masterKeyAlias,
      value: base64Encode(bytes),
    );
    return key;
  }

  // ── Evidence key derivation (HKDF-SHA256) ────────────────────

  /// Derives a per-evidence symmetric key from the master key using
  /// HKDF-SHA256 with [evidenceId] as the info parameter.
  Future<SecretKey> deriveEvidenceKey(String evidenceId) async {
    final masterKey = await getMasterKey();
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    return hkdf.deriveKey(
      secretKey: masterKey,
      nonce: <int>[],
      info: utf8.encode('evidence:$evidenceId'),
    );
  }

  // ── Ed25519 signing key pair ─────────────────────────────────

  /// Returns the persistent Ed25519 signing key pair, creating one if needed.
  Future<SimpleKeyPair> getSigningKeyPair() async {
    final stored = await _secureStorage.read(key: _signingKeyAlias);
    if (stored != null) {
      final map = jsonDecode(stored) as Map<String, dynamic>;
      return SimpleKeyPairData(
        base64Decode(map['private'] as String),
        publicKey: SimplePublicKey(
          base64Decode(map['public'] as String),
          type: KeyPairType.ed25519,
        ),
        type: KeyPairType.ed25519,
      );
    }

    final keyPair = await Ed25519().newKeyPair();
    final privateBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();

    await _secureStorage.write(
      key: _signingKeyAlias,
      value: jsonEncode({
        'private': base64Encode(privateBytes),
        'public': base64Encode(publicKey.bytes),
      }),
    );

    return keyPair;
  }

  /// Returns only the public portion of the signing key.
  Future<SimplePublicKey> getSigningPublicKey() async {
    final kp = await getSigningKeyPair();
    return kp.extractPublicKey();
  }

  // ── Key deletion (for sign-out / account wipe) ───────────────

  Future<void> deleteAllKeys() async {
    await _secureStorage.delete(key: _masterKeyAlias);
    await _secureStorage.delete(key: _signingKeyAlias);
  }
}
