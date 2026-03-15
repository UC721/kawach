import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'key_manager.dart';

/// Provides encryption, decryption, and signing for KAWACH.
///
/// KEY HIERARCHY
/// - Master key: device-bound, stored in Android Keystore / iOS Secure Enclave.
/// - Session keys: X25519 ECDH — derived per-alert, ephemeral.
/// - Evidence keys: AES-256-GCM, wrapped by master key, stored in Supabase
///   Vault.
class EncryptionService {
  EncryptionService({KeyManager? keyManager})
      : _keyManager = keyManager ?? KeyManager();

  final KeyManager _keyManager;

  // ---------------------------------------------------------------------------
  // Evidence file encryption (local + upload)
  // ---------------------------------------------------------------------------

  /// Encrypts evidence data with ChaCha20-Poly1305.
  ///
  /// Returns `nonce (12 bytes) || ciphertext || MAC (16 bytes)`.
  Future<Uint8List> encryptEvidence(Uint8List plaintext) async {
    final key = await _keyManager.deriveEvidenceKey();
    final nonce = _secureRandom(12); // 96-bit nonce
    final cipher = Chacha20.poly1305Aead();
    final secretBox = await cipher.encrypt(
      plaintext,
      secretKey: key,
      nonce: nonce,
    );
    return Uint8List.fromList([
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
  }

  /// Decrypts evidence data previously encrypted by [encryptEvidence].
  Future<Uint8List> decryptEvidence(Uint8List encrypted) async {
    final key = await _keyManager.deriveEvidenceKey();
    final nonce = encrypted.sublist(0, 12);
    final cipherText = encrypted.sublist(12, encrypted.length - 16);
    final mac = Mac(encrypted.sublist(encrypted.length - 16));
    final cipher = Chacha20.poly1305Aead();
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
    final decrypted = await cipher.decrypt(secretBox, secretKey: key);
    return Uint8List.fromList(decrypted);
  }

  // ---------------------------------------------------------------------------
  // Mesh message encryption (X25519 + ChaCha20-Poly1305)
  // ---------------------------------------------------------------------------

  /// Encrypts a mesh message for [recipientPublicKey] using X25519 ECDH
  /// key agreement and ChaCha20-Poly1305.
  ///
  /// Returns:
  /// `ephemeralPublicKey (32 bytes) || nonce (12 bytes) || ciphertext || MAC`.
  Future<Uint8List> encryptMeshMessage(
    Uint8List payload,
    Uint8List recipientPublicKey,
  ) async {
    // Generate ephemeral X25519 keypair
    final x25519 = X25519();
    final ephemeralKeyPair = await x25519.newKeyPair();
    final ephemeralPublicKey = await ephemeralKeyPair.extractPublicKey();

    // Derive shared secret via ECDH
    final remotePublicKey = SimplePublicKey(
      recipientPublicKey,
      type: KeyPairType.x25519,
    );
    final sharedSecretKey = await x25519.sharedSecretKey(
      keyPair: ephemeralKeyPair,
      remotePublicKey: remotePublicKey,
    );

    // Derive session key via HKDF
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final sharedSecretBytes = await sharedSecretKey.extractBytes();
    final sessionKey = await hkdf.deriveKey(
      secretKey: SecretKey(sharedSecretBytes),
      nonce: Uint8List(0),
      info: [...utf8.encode('kawach-mesh-v1'), ...ephemeralPublicKey.bytes],
    );

    // Encrypt with ChaCha20-Poly1305
    final nonce = _secureRandom(12);
    final cipher = Chacha20.poly1305Aead();
    final secretBox = await cipher.encrypt(
      payload,
      secretKey: sessionKey,
      nonce: nonce,
    );

    final ephemeralPubBytes = ephemeralPublicKey.bytes;
    return Uint8List.fromList([
      ...ephemeralPubBytes, // prepend ephemeral pubkey (32 bytes)
      ...nonce,
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
  }

  /// Decrypts a mesh message that was encrypted by [encryptMeshMessage].
  ///
  /// [recipientKeyPair] is the X25519 key pair of the local device.
  Future<Uint8List> decryptMeshMessage(
    Uint8List encrypted,
    SimpleKeyPair recipientKeyPair,
  ) async {
    // Parse fields
    final ephemeralPubBytes = encrypted.sublist(0, 32);
    final nonce = encrypted.sublist(32, 44);
    final cipherText = encrypted.sublist(44, encrypted.length - 16);
    final mac = Mac(encrypted.sublist(encrypted.length - 16));

    // Derive shared secret
    final x25519 = X25519();
    final remotePublicKey = SimplePublicKey(
      ephemeralPubBytes,
      type: KeyPairType.x25519,
    );
    final sharedSecretKey = await x25519.sharedSecretKey(
      keyPair: recipientKeyPair,
      remotePublicKey: remotePublicKey,
    );

    // Derive session key via HKDF
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final sharedSecretBytes = await sharedSecretKey.extractBytes();
    final sessionKey = await hkdf.deriveKey(
      secretKey: SecretKey(sharedSecretBytes),
      nonce: Uint8List(0),
      info: [...utf8.encode('kawach-mesh-v1'), ...ephemeralPubBytes],
    );

    // Decrypt
    final cipher = Chacha20.poly1305Aead();
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
    final plaintext = await cipher.decrypt(secretBox, secretKey: sessionKey);
    return Uint8List.fromList(plaintext);
  }

  // ---------------------------------------------------------------------------
  // Ed25519 signature for mesh message integrity
  // ---------------------------------------------------------------------------

  /// Signs [message] with the device's Ed25519 private key.
  Future<Uint8List> signMessage(Uint8List message) async {
    final keyPair = await _keyManager.getSigningKeyPair();
    final algorithm = Ed25519();
    final signature = await algorithm.sign(message, keyPair: keyPair);
    return Uint8List.fromList(signature.bytes);
  }

  /// Verifies an Ed25519 [signature] on [message] using [publicKey].
  Future<bool> verifySignature(
    Uint8List message,
    Uint8List signature,
    SimplePublicKey publicKey,
  ) async {
    final algorithm = Ed25519();
    final sig = Signature(signature, publicKey: publicKey);
    return algorithm.verify(message, signature: sig);
  }

  // ---------------------------------------------------------------------------
  // Secure random
  // ---------------------------------------------------------------------------

  static Uint8List _secureRandom(int length) {
    final rng = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => rng.nextInt(256)),
    );
  }
}
