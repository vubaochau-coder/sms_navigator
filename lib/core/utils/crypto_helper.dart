import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';

class CryptoHelper {
  CryptoHelper._();

  /// Độ dài GCM authentication tag (byte) — khớp 128 bit của Android native.
  static const int gcmTagLengthBytes = 16;

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

  /// Mã hóa AES-256-GCM, trả về ciphertext (nối sẵn 16-byte GCM tag) + IV
  /// dưới dạng Base64 — đúng định dạng mà Android Native (`OtpCrypto.kt`)
  /// xuất ra: `Base64(cipherText || tag)` và `Base64(iv)`.
  static Future<Map<String, String>> encryptAesGcm256({
    required String plaintext,
    required String secretKeyBase64,
  }) async {
    final algorithm = AesGcm.with256bits();
    final secretKey = await algorithm.newSecretKeyFromBytes(
      base64Decode(secretKeyBase64),
    );
    final secretBox = await algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: secretKey,
    );

    final combinedCiphertext = Uint8List.fromList([
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);

    return {
      'ciphertext': base64Encode(combinedCiphertext),
      'iv': base64Encode(secretBox.nonce),
    };
  }

  /// Giải mã AES-256-GCM từ chuỗi Base64 `ciphertext||tag` + `iv` + key,
  /// tương thích 100% với mã hóa của Android Native (`OtpCrypto.kt`).
  static Future<String> decryptAesGcm256({
    required String ciphertextWithTagBase64,
    required String ivBase64,
    required String secretKeyBase64,
  }) async {
    final fullBytes = base64Decode(ciphertextWithTagBase64);
    if (fullBytes.length < gcmTagLengthBytes) {
      throw const FormatException(
        'Ciphertext quá ngắn (thiếu GCM authentication tag).',
      );
    }
    final iv = base64Decode(ivBase64);
    final secretKeyBytes = base64Decode(secretKeyBase64);

    final cipherTextBytes = fullBytes.sublist(
      0,
      fullBytes.length - gcmTagLengthBytes,
    );
    final macBytes = fullBytes.sublist(fullBytes.length - gcmTagLengthBytes);

    final algorithm = AesGcm.with256bits();
    final secretKey = await algorithm.newSecretKeyFromBytes(secretKeyBytes);
    final secretBox = SecretBox(cipherTextBytes, nonce: iv, mac: Mac(macBytes));

    final clearTextBytes = await algorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );
    return utf8.decode(clearTextBytes);
  }
}
