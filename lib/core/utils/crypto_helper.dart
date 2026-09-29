import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class CryptoHelper {
  CryptoHelper._();

  /// Generates a random 32-byte Base64 key string.
  static String generateSecretKeyBase64() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// Computes SHA-256 hash string of input.
  static String sha256Hash(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }
}
