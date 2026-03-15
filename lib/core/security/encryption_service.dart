import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'key_manager.dart';

/// Provides ChaCha20-Poly1305 evidence encryption, X25519 ECDH key-agreement
/// for mesh-message encryption, and Ed25519 digital signatures.
class EncryptionService {
  final KeyManager _keyManager;

  // Algorithm singletons
  final _chacha = Chacha20.poly1305Aead();
  final _x25519 = X25519();
  final _ed25519 = Ed25519();

  EncryptionService(this._keyManager);

  // ── Evidence encryption (ChaCha20-Poly1305) ──────────────────

  /// Encrypts [plaintext] using a per-evidence key derived via HKDF-SHA256.
  /// Returns `{nonce || ciphertext || mac}`.
  Future<Uint8List> encryptEvidence(
    Uint8List plaintext,
    String evidenceId,
  ) async {
    final secretKey = await _keyManager.deriveEvidenceKey(evidenceId);
    final nonce = _chacha.newNonce();

    final secretBox = await _chacha.encrypt(
      plaintext,
      secretKey: secretKey,
      nonce: nonce,
    );

    // Pack: nonce (12) + ciphertext + mac (16)
    final nonceBytes = Uint8List.fromList(secretBox.nonce);
    final cipherBytes = Uint8List.fromList(secretBox.cipherText);
    final macBytes = Uint8List.fromList(secretBox.mac.bytes);

    final result = Uint8List(nonceBytes.length + cipherBytes.length + macBytes.length);
    result.setAll(0, nonceBytes);
    result.setAll(nonceBytes.length, cipherBytes);
    result.setAll(nonceBytes.length + cipherBytes.length, macBytes);
    return result;
  }

  /// Decrypts evidence that was encrypted with [encryptEvidence].
  Future<Uint8List> decryptEvidence(
    Uint8List packed,
    String evidenceId,
  ) async {
    final secretKey = await _keyManager.deriveEvidenceKey(evidenceId);

    const nonceLen = 12;
    const macLen = 16;

    final nonce = packed.sublist(0, nonceLen);
    final cipherText = packed.sublist(nonceLen, packed.length - macLen);
    final macBytes = packed.sublist(packed.length - macLen);

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final plaintext = await _chacha.decrypt(
      secretBox,
      secretKey: secretKey,
    );

    return Uint8List.fromList(plaintext);
  }

  // ── Mesh message encryption (X25519 + ChaCha20-Poly1305) ────

  /// Generates an ephemeral X25519 key pair for a single mesh hop.
  Future<SimpleKeyPair> generateMeshKeyPair() {
    return _x25519.newKeyPair();
  }

  /// Encrypts a mesh message for the given [peerPublicKey] using X25519
  /// ECDH shared secret + HKDF + ChaCha20-Poly1305.
  Future<Uint8List> encryptMeshMessage(
    Uint8List plaintext,
    SimpleKeyPair senderKeyPair,
    SimplePublicKey peerPublicKey,
  ) async {
    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: senderKeyPair,
      remotePublicKey: peerPublicKey,
    );

    // Derive a symmetric key from the shared secret via HKDF-SHA256
    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final derivedKey = await hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: <int>[],
      info: 'kawach-mesh-v1'.codeUnits,
    );

    final nonce = _chacha.newNonce();
    final secretBox = await _chacha.encrypt(
      plaintext,
      secretKey: derivedKey,
      nonce: nonce,
    );

    // Pack: nonce (12) + ciphertext + mac (16)
    final nonceBytes = Uint8List.fromList(secretBox.nonce);
    final cipherBytes = Uint8List.fromList(secretBox.cipherText);
    final macBytes = Uint8List.fromList(secretBox.mac.bytes);

    final result = Uint8List(nonceBytes.length + cipherBytes.length + macBytes.length);
    result.setAll(0, nonceBytes);
    result.setAll(nonceBytes.length, cipherBytes);
    result.setAll(nonceBytes.length + cipherBytes.length, macBytes);
    return result;
  }

  /// Decrypts a mesh message received from [senderPublicKey].
  Future<Uint8List> decryptMeshMessage(
    Uint8List packed,
    SimpleKeyPair receiverKeyPair,
    SimplePublicKey senderPublicKey,
  ) async {
    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: receiverKeyPair,
      remotePublicKey: senderPublicKey,
    );

    final hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
    final derivedKey = await hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: <int>[],
      info: 'kawach-mesh-v1'.codeUnits,
    );

    const nonceLen = 12;
    const macLen = 16;

    final nonce = packed.sublist(0, nonceLen);
    final cipherText = packed.sublist(nonceLen, packed.length - macLen);
    final macBytes = packed.sublist(packed.length - macLen);

    final secretBox = SecretBox(
      cipherText,
      nonce: nonce,
      mac: Mac(macBytes),
    );

    final plaintext = await _chacha.decrypt(
      secretBox,
      secretKey: derivedKey,
    );

    return Uint8List.fromList(plaintext);
  }

  // ── Ed25519 digital signatures ───────────────────────────────

  /// Signs [data] with the user's Ed25519 signing key.
  Future<Signature> sign(Uint8List data) async {
    final keyPair = await _keyManager.getSigningKeyPair();
    return _ed25519.sign(data, keyPair: keyPair);
  }

  /// Verifies an Ed25519 [signature] against [data] and [publicKey].
  Future<bool> verify(
    Uint8List data,
    Signature signature,
    SimplePublicKey publicKey,
  ) async {
    return _ed25519.verify(data, signature: signature);
  }
}
