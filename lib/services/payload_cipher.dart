import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../utils/constants.dart';

class PayloadCipher {
  PayloadCipher._();

  static String encryptObject(
    Map<String, dynamic> value, {
    required String scope,
  }) {
    return encrypt(utf8.encode(jsonEncode(value)), scope: scope);
  }

  static String encrypt(
    List<int> data, {
    required String scope,
  }) {
    final nonce = _randomBytes(16);
    final key = _deriveKey(scope, nonce);
    final cipherBytes = Uint8List(data.length);

    for (var index = 0; index < data.length; index++) {
      cipherBytes[index] = data[index] ^ key[index % key.length];
    }

    final mac = Hmac(
      sha256,
      _deriveMacKey(scope, nonce),
    ).convert(cipherBytes);

    return jsonEncode({
      'nonce': base64Encode(nonce),
      'payload': base64Encode(cipherBytes),
      'mac': base64Encode(mac.bytes),
    });
  }

  static Map<String, dynamic>? tryDecryptObject(
    String encrypted, {
    required String scope,
  }) {
    final decoded = tryDecrypt(encrypted, scope: scope);
    if (decoded == null) {
      return null;
    }

    return jsonDecode(utf8.decode(decoded)) as Map<String, dynamic>;
  }

  static Uint8List? tryDecrypt(
    String encrypted, {
    required String scope,
  }) {
    try {
      final envelope = jsonDecode(encrypted) as Map<String, dynamic>;
      final nonce = base64Decode(envelope['nonce'] as String);
      final payload = base64Decode(envelope['payload'] as String);
      final receivedMac = base64Decode(envelope['mac'] as String);
      final expectedMac = Hmac(
        sha256,
        _deriveMacKey(scope, nonce),
      ).convert(payload);

      if (!_constantTimeEquals(receivedMac, expectedMac.bytes)) {
        return null;
      }

      final key = _deriveKey(scope, nonce);
      final plainText = Uint8List(payload.length);
      for (var index = 0; index < payload.length; index++) {
        plainText[index] = payload[index] ^ key[index % key.length];
      }

      return plainText;
    } catch (_) {
      return null;
    }
  }

  static Uint8List _deriveKey(String scope, List<int> nonce) {
    final digest = sha256.convert([
      ...utf8.encode(AppKeys.emergencyCipherSeed),
      ...utf8.encode(scope),
      ...nonce,
    ]);
    return Uint8List.fromList(digest.bytes);
  }

  static List<int> _deriveMacKey(String scope, List<int> nonce) {
    return sha256
        .convert([
          ...utf8.encode('mac'),
          ...utf8.encode(AppKeys.emergencyCipherSeed),
          ...utf8.encode(scope),
          ...nonce,
        ])
        .bytes;
  }

  static List<int> _randomBytes(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }

  static bool _constantTimeEquals(List<int> left, List<int> right) {
    if (left.length != right.length) {
      return false;
    }

    var result = 0;
    for (var index = 0; index < left.length; index++) {
      result |= left[index] ^ right[index];
    }
    return result == 0;
  }
}
