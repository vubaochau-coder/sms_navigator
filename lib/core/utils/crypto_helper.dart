import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:cryptography/cryptography.dart';

class CryptoHelper {
  CryptoHelper._();

  /// Độ dài GCM authentication tag (byte) — khớp 128 bit của Android native.
  static const int gcmTagLengthBytes = 16;

  /// HKDF `info` cố định cho Handshake ghép đôi — đổi khi nâng giao thức.
  static const String _pairingHkdfInfo = 'sms-navigator-pair-v3';

  static final X25519 _x25519 = X25519();
  static final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);

  /// Generates a random 32-byte Base64 key string.
  static String generateSecretKeyBase64() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// Sinh cặp khóa X25519 dùng một lần cho Handshake ghép đôi.
  ///
  /// Private key lưu dưới dạng seed 32 byte (Base64) — tái tạo được key pair
  /// gốc bằng [newKeyPairFromSeed] nên không cần giữ object trong bộ nhớ.
  static Future<({String publicKeyBase64, String privateKeyBase64})>
      generateX25519KeyPairBase64() async {
    final random = Random.secure();
    final seed = Uint8List.fromList(
      List<int>.generate(32, (_) => random.nextInt(256)),
    );
    final keyPair = await _x25519.newKeyPairFromSeed(seed);
    final publicKey = await keyPair.extractPublicKey();
    return (
      publicKeyBase64: base64Encode(publicKey.bytes),
      privateKeyBase64: base64Encode(seed),
    );
  }

  /// Derive shared secret 32 byte (AES-256) từ ECDH X25519 + HKDF-SHA256.
  ///
  /// Cả hai bên gọi với (private của mình, public của đối tác, salt = pairId)
  /// sẽ ra cùng một kết quả. Máy chủ chỉ thấy public key — không thể derive.
  static Future<String> derivePairingSecretBase64({
    required String privateKeyBase64,
    required String remotePublicKeyBase64,
    required String salt,
  }) async {
    final keyPair = await _x25519.newKeyPairFromSeed(
      base64Decode(privateKeyBase64),
    );
    final remoteKey = SimplePublicKey(
      base64Decode(remotePublicKeyBase64),
      type: KeyPairType.x25519,
    );
    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: keyPair,
      remotePublicKey: remoteKey,
    );
    final derived = await _hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: utf8.encode(salt),
      info: utf8.encode(_pairingHkdfInfo),
    );
    return base64Encode(await derived.extractBytes());
  }

  /// Computes SHA-256 hash string of input.
  static String sha256Hash(String input) {
    return crypto.sha256.convert(utf8.encode(input)).toString();
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
