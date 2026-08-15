import 'dart:convert';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'encryption_service.dart';

// ============================================================
// KeyManager – Persistent key storage (secure_storage backed)
// ============================================================

/// Manages cryptographic key lifecycle.
///
/// In production, replace [SharedPreferences] with `flutter_secure_storage`
/// for hardware-backed key storage on both Android (Keystore) and
/// iOS (Keychain).
class KeyManager {
  static const _symmetricKeyAlias = 'kawach_symmetric_key';
  static const _identityKeyAlias = 'kawach_identity_key';

  /// Retrieve or lazily create the device's symmetric encryption key.
  Future<Uint8List> getOrCreateSymmetricKey() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_symmetricKeyAlias);
    if (stored != null) {
      return base64Decode(stored);
    }
    final key = EncryptionService.generateKey();
    await prefs.setString(_symmetricKeyAlias, base64Encode(key));
    return key;
  }

  /// Retrieve or lazily create the device's identity key (Ed25519 seed).
  Future<Uint8List> getOrCreateIdentityKey() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_identityKeyAlias);
    if (stored != null) {
      return base64Decode(stored);
    }
    // 32-byte seed for Ed25519
    final seed = EncryptionService.generateKey();
    await prefs.setString(_identityKeyAlias, base64Encode(seed));
    return seed;
  }

  /// Delete all stored keys (e.g. on account logout / wipe).
  Future<void> clearKeys() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_symmetricKeyAlias);
    await prefs.remove(_identityKeyAlias);
  }
}
