import 'package:flutter_test/flutter_test.dart';
import 'package:kawach/services/mesh/mesh_crypto_service.dart';

void main() {
  group('MeshCryptoService', () {
    late MeshCryptoService crypto;
    late String key;

    setUp(() {
      crypto = MeshCryptoService();
      key = crypto.deriveKey('test-passphrase');
    });

    // ── Key derivation ────────────────────────────────────────────

    test('deriveKey returns 64-char hex string (256-bit key)', () {
      expect(key.length, 64);
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(key), true);
    });

    test('deriveKey is deterministic for same passphrase and salt', () {
      final key2 = crypto.deriveKey('test-passphrase');
      expect(key2, key);
    });

    test('deriveKey differs for different passphrases', () {
      final other = crypto.deriveKey('other-passphrase');
      expect(other, isNot(equals(key)));
    });

    test('deriveKey differs for different salts', () {
      final salted = crypto.deriveKey('test-passphrase', salt: 'custom-salt');
      expect(salted, isNot(equals(key)));
    });

    // ── Encryption / decryption ───────────────────────────────────

    test('encrypt returns non-empty Base-64 string', () {
      final ct = crypto.encrypt('hello world', key);
      expect(ct.isNotEmpty, true);
      // Must be valid Base-64.
      expect(() => crypto.decrypt(ct, key), returnsNormally);
    });

    test('decrypt recovers original plaintext', () {
      const plaintext = 'emergency at 12.34, 56.78';
      final ct = crypto.encrypt(plaintext, key);
      final pt = crypto.decrypt(ct, key);
      expect(pt, plaintext);
    });

    test('encrypting same plaintext twice yields different ciphertext', () {
      const plaintext = 'same message';
      final ct1 = crypto.encrypt(plaintext, key);
      final ct2 = crypto.encrypt(plaintext, key);
      // Different IVs → different ciphertexts.
      expect(ct1, isNot(equals(ct2)));
    });

    test('decryption with wrong key throws', () {
      const plaintext = 'secret data';
      final ct = crypto.encrypt(plaintext, key);
      final wrongKey = crypto.deriveKey('wrong-passphrase');
      expect(() => crypto.decrypt(ct, wrongKey), throwsA(anything));
    });

    test('round-trips Unicode content', () {
      const plaintext = '🆘 बचाओ! Help! 助けて!';
      final ct = crypto.encrypt(plaintext, key);
      expect(crypto.decrypt(ct, key), plaintext);
    });

    test('round-trips empty string', () {
      final ct = crypto.encrypt('', key);
      expect(crypto.decrypt(ct, key), '');
    });

    // ── HMAC signing ──────────────────────────────────────────────

    test('sign returns 64-char hex string (SHA-256)', () {
      final sig = crypto.sign('some data', key);
      expect(sig.length, 64);
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(sig), true);
    });

    test('verify returns true for valid signature', () {
      const data = 'important payload';
      final sig = crypto.sign(data, key);
      expect(crypto.verify(data, sig, key), true);
    });

    test('verify returns false for tampered data', () {
      final sig = crypto.sign('original', key);
      expect(crypto.verify('tampered', sig, key), false);
    });

    test('verify returns false for wrong key', () {
      const data = 'payload';
      final sig = crypto.sign(data, key);
      final wrongKey = crypto.deriveKey('wrong');
      expect(crypto.verify(data, sig, wrongKey), false);
    });
  });
}
