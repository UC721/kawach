import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../../core/security/encryption_service.dart';

/// Per-hop encryption layer for mesh emergency relay messages.
///
/// Each hop negotiates an ephemeral X25519 key pair and encrypts the payload
/// with ChaCha20-Poly1305. The [EncryptionService] handles the underlying
/// cryptographic operations.
class MeshCryptoService {
  final EncryptionService _encryption;
  final _ed25519 = Ed25519();

  MeshCryptoService(this._encryption);

  /// Wraps [payload] in a per-hop encrypted + signed envelope.
  ///
  /// Returns a [MeshSecureEnvelope] containing the sender's ephemeral public
  /// key, the encrypted payload, and an Ed25519 signature over the ciphertext.
  Future<MeshSecureEnvelope> wrapForHop(
    Uint8List payload,
    SimplePublicKey peerPublicKey,
  ) async {
    // 1. Generate ephemeral key pair for this hop
    final ephemeralKP = await _encryption.generateMeshKeyPair();
    final ephemeralPublicKey = await ephemeralKP.extractPublicKey();

    // 2. Encrypt payload using X25519 ECDH + ChaCha20-Poly1305
    final encrypted = await _encryption.encryptMeshMessage(
      payload,
      ephemeralKP,
      peerPublicKey,
    );

    // 3. Sign the ciphertext with the device's Ed25519 key
    final signature = await _encryption.sign(encrypted);

    return MeshSecureEnvelope(
      senderEphemeralPublicKey: ephemeralPublicKey,
      encryptedPayload: encrypted,
      signature: Uint8List.fromList(signature.bytes),
    );
  }

  /// Unwraps a [MeshSecureEnvelope] received from a peer.
  ///
  /// [receiverKeyPair] is the local device's key pair used to derive the
  /// shared secret. [senderSigningKey] is used to verify the signature.
  Future<Uint8List> unwrapFromHop(
    MeshSecureEnvelope envelope,
    SimpleKeyPair receiverKeyPair,
    SimplePublicKey senderSigningKey,
  ) async {
    // 1. Verify the Ed25519 signature over the ciphertext
    final isValid = await _ed25519.verify(
      envelope.encryptedPayload,
      signature: Signature(
        envelope.signature,
        publicKey: senderSigningKey,
      ),
    );
    if (!isValid) {
      throw MeshCryptoException('Invalid signature on mesh message');
    }

    // 2. Decrypt using X25519 ECDH + ChaCha20-Poly1305
    return _encryption.decryptMeshMessage(
      envelope.encryptedPayload,
      receiverKeyPair,
      envelope.senderEphemeralPublicKey,
    );
  }
}

/// Encrypted + signed mesh message envelope for a single hop.
class MeshSecureEnvelope {
  final SimplePublicKey senderEphemeralPublicKey;
  final Uint8List encryptedPayload;
  final Uint8List signature;

  const MeshSecureEnvelope({
    required this.senderEphemeralPublicKey,
    required this.encryptedPayload,
    required this.signature,
  });
}

/// Exception thrown when mesh message verification or decryption fails.
class MeshCryptoException implements Exception {
  final String message;
  const MeshCryptoException(this.message);

  @override
  String toString() => 'MeshCryptoException: $message';
}
