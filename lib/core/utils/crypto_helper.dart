import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class CryptoHelper {
  CryptoHelper._();

  /// Generates a random 6-digit numeric pairing code (e.g., "582914").
  static String generatePairingCode() {
    final random = Random.secure();
    final code = 100000 + random.nextInt(900000);
    return code.toString();
  }

  /// Generates a random 32-byte Base64 key string.
  static String generateSecretKeyBase64() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// Derives a 32-byte (256-bit) AES key from a pairing code and a salt.
  static String deriveKeyFromCode(String code, String salt) {
    final keyBytes = utf8.encode(code);
    final saltBytes = utf8.encode(salt);
    final hmacSha256 = Hmac(sha256, keyBytes);
    final digest = hmacSha256.convert(saltBytes);
    return base64Encode(digest.bytes);
  }

  /// Computes SHA-256 hash string of input.
  static String sha256Hash(String input) {
    return sha256.convert(utf8.encode(input)).toString();
  }
}
