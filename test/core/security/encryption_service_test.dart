import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kawach/core/security/encryption_service.dart';
import 'package:kawach/core/security/key_manager.dart';

/// Fake [FlutterSecureStorage] that stores values in-memory for testing.
///
/// We avoid importing flutter_secure_storage directly because its platform
/// channel is unavailable during pure-Dart unit tests.  Instead, [KeyManager]
/// accepts an optional storage instance, so we provide this fake.
// ignore: depend_on_referenced_packages
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class FakeSecureStorage implements FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _store[key] = value;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late KeyManager keyManager;
  late EncryptionService encryptionService;

  setUp(() {
    keyManager = KeyManager(secureStorage: FakeSecureStorage());
    encryptionService = EncryptionService(keyManager: keyManager);
  });

  // ---------------------------------------------------------------------------
  // Evidence encryption
  // ---------------------------------------------------------------------------

  group('encryptEvidence / decryptEvidence', () {
    test('round-trips arbitrary plaintext', () async {
      final plaintext = Uint8List.fromList(
        List.generate(256, (i) => i % 256),
      );
      final encrypted = await encryptionService.encryptEvidence(plaintext);

      // Encrypted output must be longer (nonce + MAC overhead).
      expect(encrypted.length, greaterThan(plaintext.length));

      final decrypted = await encryptionService.decryptEvidence(encrypted);
      expect(decrypted, equals(plaintext));
    });

    test('encrypts empty plaintext', () async {
      final plaintext = Uint8List(0);
      final encrypted = await encryptionService.encryptEvidence(plaintext);

      // At minimum nonce (12) + MAC (16) = 28 bytes even for empty input.
      expect(encrypted.length, greaterThanOrEqualTo(28));

      final decrypted = await encryptionService.decryptEvidence(encrypted);
      expect(decrypted, equals(plaintext));
    });

    test('produces different ciphertext on each call (unique nonces)',
        () async {
      final plaintext = Uint8List.fromList([1, 2, 3, 4, 5]);
      final a = await encryptionService.encryptEvidence(plaintext);
      final b = await encryptionService.encryptEvidence(plaintext);
      // Nonces differ → ciphertext differs.
      expect(a, isNot(equals(b)));
    });
  });

  // ---------------------------------------------------------------------------
  // Mesh message encryption
  // ---------------------------------------------------------------------------

  group('encryptMeshMessage / decryptMeshMessage', () {
    test('round-trips a message via X25519 + ChaCha20-Poly1305', () async {
      final x25519 = X25519();
      final recipientKeyPair = await x25519.newKeyPair();
      final recipientPublicKey = await recipientKeyPair.extractPublicKey();

      final payload = Uint8List.fromList('hello kawach mesh'.codeUnits);
      final encrypted = await encryptionService.encryptMeshMessage(
        payload,
        Uint8List.fromList(recipientPublicKey.bytes),
      );

      // Header: 32 (ephemeral pubkey) + 12 (nonce) = 44 bytes minimum.
      expect(encrypted.length, greaterThan(44));

      final decrypted = await encryptionService.decryptMeshMessage(
        encrypted,
        recipientKeyPair as SimpleKeyPair,
      );
      expect(decrypted, equals(payload));
    });
  });

  // ---------------------------------------------------------------------------
  // Ed25519 signing
  // ---------------------------------------------------------------------------

  group('signMessage / verifySignature', () {
    test('produces a valid Ed25519 signature', () async {
      final message = Uint8List.fromList('test-integrity'.codeUnits);
      final signature = await encryptionService.signMessage(message);

      // Ed25519 signatures are 64 bytes.
      expect(signature.length, equals(64));

      // Verify with the public key.
      final keyPair = await keyManager.getSigningKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      final valid = await encryptionService.verifySignature(
        message,
        signature,
        publicKey as SimplePublicKey,
      );
      expect(valid, isTrue);
    });

    test('rejects a tampered message', () async {
      final message = Uint8List.fromList('original'.codeUnits);
      final signature = await encryptionService.signMessage(message);

      final tampered = Uint8List.fromList('tampered'.codeUnits);
      final keyPair = await keyManager.getSigningKeyPair();
      final publicKey = await keyPair.extractPublicKey();
      final valid = await encryptionService.verifySignature(
        tampered,
        signature,
        publicKey as SimplePublicKey,
      );
      expect(valid, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // Key manager
  // ---------------------------------------------------------------------------

  group('KeyManager', () {
    test('returns the same master key across calls', () async {
      final a = await keyManager.getMasterKey();
      final b = await keyManager.getMasterKey();
      expect(await a.extractBytes(), equals(await b.extractBytes()));
    });

    test('returns the same signing key pair across calls', () async {
      final a = await keyManager.getSigningKeyPair();
      final b = await keyManager.getSigningKeyPair();
      final aBytes = await a.extractPrivateKeyBytes();
      final bBytes = await b.extractPrivateKeyBytes();
      expect(aBytes, equals(bBytes));
    });
  });
}
