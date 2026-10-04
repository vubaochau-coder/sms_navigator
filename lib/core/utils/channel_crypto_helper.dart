import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';
import 'package:equatable/equatable.dart';

import '../crypto/canonical_encoding.dart';

/// Cặp khóa định danh X25519 của thiết bị (SRD 3.1).
///
/// Private key là seed 32 byte (Base64) — tái tạo lại key pair gốc bằng
/// [X25519.newKeyPairFromSeed] nên không cần giữ object khóa trong bộ nhớ.
class IdentityKeyPair extends Equatable {
  final String publicKeyBase64;
  final String privateKeyBase64;

  const IdentityKeyPair({
    required this.publicKeyBase64,
    required this.privateKeyBase64,
  });

  @override
  List<Object?> get props => [publicKeyBase64, privateKeyBase64];
}

/// Envelope khóa kênh sau khi wrap cho một thiết bị cụ thể (SRD 7.2):
/// `wrapped_key` là Base64(ciphertext || tag) của AES-256-GCM với KEK.
class KeyEnvelope extends Equatable {
  final int keyEpoch;
  final String wrappedKeyBase64;
  final String nonceBase64;
  final String kekAlg;

  const KeyEnvelope({
    required this.keyEpoch,
    required this.wrappedKeyBase64,
    required this.nonceBase64,
    this.kekAlg = 'X25519-ECDH-HKDF-SHA256/AES-256-GCM',
  });

  Map<String, dynamic> toMap() => {
    'key_epoch': keyEpoch,
    'wrapped_key': wrappedKeyBase64,
    'nonce': nonceBase64,
    'kek_alg': kekAlg,
  };

  @override
  List<Object?> get props => [keyEpoch, wrappedKeyBase64, nonceBase64, kekAlg];
}

/// Kết quả mã hóa một tin nhắn: ciphertext (nối sẵn GCM tag) + nonce 12B.
class EncryptedMessage extends Equatable {
  final String ciphertextBase64;
  final String nonceBase64;

  const EncryptedMessage({
    required this.ciphertextBase64,
    required this.nonceBase64,
  });

  @override
  List<Object?> get props => [ciphertextBase64, nonceBase64];
}

/// Lỗi mật mã của kênh: unwrap/mã hóa/giải mã thất bại (AAD sai, tag hỏng,
/// khóa không đúng định dạng...).
class ChannelCryptoException implements Exception {
  final String message;
  const ChannelCryptoException(this.message);

  @override
  String toString() => message;
}

/// Helper mật mã cho kiến trúc Kênh 1-to-N E2EE — khớp chính xác Hợp đồng
/// Mật mã SRD §7 (v1.6):
///
/// - Owner là key authority: envelope wrap bằng **static ECDH**
///   `sk_owner × pk_member` (không ephemeral). Self-envelope của Owner dùng
///   `ECDH(sk_A, pk_A)` — phép toán hợp lệ trên X25519 (SRD 7.2).
/// - `KEK = HKDF-SHA256(ikm = ECDH, salt = SHA256(salt-v1 || ch || epoch),
///   info = 'sms-navigator-kek-v1', L = 32)`.
/// - Envelope AAD = `bind(ch, epoch, device_id)` (KL9); Message AAD =
///   `bind(ch, epoch, seq_hint)` (KL10) — canonical encoding riêng ở
///   [CanonicalEncoding].
/// - AES-256-GCM, nonce 12 byte random, output `Base64(ciphertext || tag)`.
class ChannelCryptoHelper {
  ChannelCryptoHelper({Random? random}) : _random = random ?? Random.secure();

  static const String kekHkdfInfo = 'sms-navigator-kek-v1';

  /// Độ dài GCM authentication tag (byte) — output là ciphertext || tag.
  static const int gcmTagLengthBytes = 16;

  static final X25519 _x25519 = X25519();
  static final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  static final AesGcm _aesGcm = AesGcm.with256bits();

  final Random _random;

  Uint8List _randomBytes(int length) => Uint8List.fromList(
    List<int>.generate(length, (_) => _random.nextInt(256)),
  );

  /// Sinh cặp khóa định danh X25519 mới (32 byte random mỗi phía).
  Future<IdentityKeyPair> generateX25519IdentityKeyPair() async {
    final seed = _randomBytes(32);
    final keyPair = await _x25519.newKeyPairFromSeed(seed);
    final publicKey = await keyPair.extractPublicKey();
    return IdentityKeyPair(
      publicKeyBase64: base64Encode(publicKey.bytes),
      privateKeyBase64: base64Encode(seed),
    );
  }

  /// Sinh Channel Key AES-256 (32 byte random, Base64) — chỉ Owner thực hiện.
  String generateChannelKeyBase64() => base64Encode(_randomBytes(32));

  Future<SimpleKeyPair> _keyPairFromSeedBase64(String seedBase64) async {
    final Uint8List seed;
    try {
      seed = base64Decode(seedBase64);
    } on FormatException {
      throw const ChannelCryptoException('Private key không đúng Base64.');
    }
    if (seed.length != 32) {
      throw const ChannelCryptoException(
        'Private key seed phải có đúng 32 byte.',
      );
    }
    return _x25519.newKeyPairFromSeed(seed);
  }

  /// KEK = HKDF-SHA256(ECDH(sk_sender, pk_receiver),
  ///   salt = SHA256('sms-navigator-salt-v1' || lenPref(ch) || u64(epoch)),
  ///   info = 'sms-navigator-kek-v1', L = 32).
  Future<SecretKey> _deriveKek({
    required SimpleKeyPair senderKeyPair,
    required String receiverPublicKeyBase64,
    required String channelId,
    required int keyEpoch,
  }) async {
    final Uint8List remoteBytes;
    try {
      remoteBytes = base64Decode(receiverPublicKeyBase64);
    } on FormatException {
      throw const ChannelCryptoException('Public key không đúng Base64.');
    }
    final receiverKey = SimplePublicKey(remoteBytes, type: KeyPairType.x25519);
    final sharedSecret = await _x25519.sharedSecretKey(
      keyPair: senderKeyPair,
      remotePublicKey: receiverKey,
    );
    return _hkdf.deriveKey(
      secretKey: sharedSecret,
      nonce: CanonicalEncoding.kekSalt(channelId: channelId, keyEpoch: keyEpoch),
      info: utf8.encode(kekHkdfInfo),
    );
  }

  /// AES-256-GCM encrypt với AAD; trả về Base64(ciphertext || tag) + nonce.
  Future<({String ciphertextBase64, String nonceBase64})> _encryptWithAad({
    required SecretKey key,
    required List<int> plaintext,
    required List<int> aad,
  }) async {
    final secretBox = await _aesGcm.encrypt(
      plaintext,
      secretKey: key,
      aad: aad,
    );
    final combined = Uint8List.fromList([
      ...secretBox.cipherText,
      ...secretBox.mac.bytes,
    ]);
    return (
      ciphertextBase64: base64Encode(combined),
      nonceBase64: base64Encode(secretBox.nonce),
    );
  }

  /// AES-256-GCM decrypt từ Base64(ciphertext || tag) + nonce + AAD.
  Future<List<int>> _decryptWithAad({
    required SecretKey key,
    required String ciphertextWithTagBase64,
    required String nonceBase64,
    required List<int> aad,
  }) async {
    final Uint8List fullBytes;
    final Uint8List nonceBytes;
    try {
      fullBytes = base64Decode(ciphertextWithTagBase64);
      nonceBytes = base64Decode(nonceBase64);
    } on FormatException {
      throw const ChannelCryptoException(
        'Dữ liệu mã hóa/nonce không đúng định dạng Base64.',
      );
    }
    if (fullBytes.length < gcmTagLengthBytes) {
      throw const ChannelCryptoException(
        'Dữ liệu mã hóa quá ngắn (thiếu GCM authentication tag).',
      );
    }
    final cipherTextBytes = fullBytes.sublist(
      0,
      fullBytes.length - gcmTagLengthBytes,
    );
    final macBytes = fullBytes.sublist(fullBytes.length - gcmTagLengthBytes);
    try {
      final secretBox = SecretBox(
        cipherTextBytes,
        nonce: nonceBytes,
        mac: Mac(macBytes),
      );
      return await _aesGcm.decrypt(secretBox, secretKey: key, aad: aad);
    } on SecretBoxAuthenticationError {
      throw const ChannelCryptoException(
        'Xác thực AES-GCM thất bại: dữ liệu hoặc AAD không khớp.',
      );
    }
  }

  /// Wrap key envelope cho một thiết bị (Owner-side, T0/T2/T4 — SRD 7.2).
  ///
  /// KEK = HKDF(ECDH(sk_owner, pk_receiver)); AAD = bindEnv(ch, epoch, dev).
  /// [channelKeyBase64] là chuỗi Base64 của CK, được mã hóa như UTF-8.
  Future<KeyEnvelope> wrapKeyForDevice({
    required String channelKeyBase64,
    required String ownerPrivateKeyBase64,
    required String receiverPublicKeyBase64,
    required String channelId,
    required int keyEpoch,
    required String receiverDeviceId,
  }) async {
    final ownerKeyPair = await _keyPairFromSeedBase64(ownerPrivateKeyBase64);
    final kek = await _deriveKek(
      senderKeyPair: ownerKeyPair,
      receiverPublicKeyBase64: receiverPublicKeyBase64,
      channelId: channelId,
      keyEpoch: keyEpoch,
    );
    final aad = CanonicalEncoding.envelopeAad(
      channelId: channelId,
      keyEpoch: keyEpoch,
      deviceId: receiverDeviceId,
    );
    final encrypted = await _encryptWithAad(
      key: kek,
      plaintext: utf8.encode(channelKeyBase64),
      aad: aad,
    );
    return KeyEnvelope(
      keyEpoch: keyEpoch,
      wrappedKeyBase64: encrypted.ciphertextBase64,
      nonceBase64: encrypted.nonceBase64,
    );
  }

  /// Mở key envelope (Member-side / Owner recovery — SRD 7.3):
  /// KEK = HKDF(ECDH(sk_my, pk_owner)) → AES-256-GCM decrypt với AAD ràng
  /// buộc (channel, epoch, device). Trả về Channel Key dạng Base64.
  Future<String> unwrapKeyEnvelope({
    required String wrappedKeyBase64,
    required String nonceBase64,
    required String myPrivateKeyBase64,
    required String ownerPublicKeyBase64,
    required String channelId,
    required int keyEpoch,
    required String myDeviceId,
  }) async {
    final myKeyPair = await _keyPairFromSeedBase64(myPrivateKeyBase64);
    final kek = await _deriveKek(
      senderKeyPair: myKeyPair,
      receiverPublicKeyBase64: ownerPublicKeyBase64,
      channelId: channelId,
      keyEpoch: keyEpoch,
    );
    final aad = CanonicalEncoding.envelopeAad(
      channelId: channelId,
      keyEpoch: keyEpoch,
      deviceId: myDeviceId,
    );
    final plainBytes = await _decryptWithAad(
      key: kek,
      ciphertextWithTagBase64: wrappedKeyBase64,
      nonceBase64: nonceBase64,
      aad: aad,
    );
    return utf8.decode(plainBytes);
  }

  /// Mã hóa tin nhắn bằng Channel Key của epoch hiện hành (Owner, 5.2).
  /// AAD = bindMsg(ch, epoch, sequenceHint) — mặc định `0` vì server mới cấp
  /// sequence sau khi nhận (API spec §11).
  Future<EncryptedMessage> encryptMessage({
    required String plaintext,
    required String channelKeyBase64,
    required String channelId,
    required int keyEpoch,
    int sequenceHint = 0,
  }) async {
    final Uint8List keyBytes;
    try {
      keyBytes = base64Decode(channelKeyBase64);
    } on FormatException {
      throw const ChannelCryptoException('Channel Key không đúng Base64.');
    }
    if (keyBytes.length != 32) {
      throw const ChannelCryptoException(
        'Channel Key phải có đúng 32 byte (AES-256).',
      );
    }
    final key = await _aesGcm.newSecretKeyFromBytes(keyBytes);
    final aad = CanonicalEncoding.messageAad(
      channelId: channelId,
      keyEpoch: keyEpoch,
      sequenceHint: sequenceHint,
    );
    final encrypted = await _encryptWithAad(
      key: key,
      plaintext: utf8.encode(plaintext),
      aad: aad,
    );
    return EncryptedMessage(
      ciphertextBase64: encrypted.ciphertextBase64,
      nonceBase64: encrypted.nonceBase64,
    );
  }

  /// Giải mã tin nhắn bằng Channel Key của epoch tương ứng (Member, 6.2).
  /// AAD phải khớp lúc mã hóa — dùng cùng [sequenceHint].
  Future<String> decryptMessage({
    required String ciphertextBase64,
    required String nonceBase64,
    required String channelKeyBase64,
    required String channelId,
    required int keyEpoch,
    int sequenceHint = 0,
  }) async {
    final Uint8List keyBytes;
    try {
      keyBytes = base64Decode(channelKeyBase64);
    } on FormatException {
      throw const ChannelCryptoException('Channel Key không đúng Base64.');
    }
    if (keyBytes.length != 32) {
      throw const ChannelCryptoException(
        'Channel Key phải có đúng 32 byte (AES-256).',
      );
    }
    final key = await _aesGcm.newSecretKeyFromBytes(keyBytes);
    final aad = CanonicalEncoding.messageAad(
      channelId: channelId,
      keyEpoch: keyEpoch,
      sequenceHint: sequenceHint,
    );
    final plainBytes = await _decryptWithAad(
      key: key,
      ciphertextWithTagBase64: ciphertextBase64,
      nonceBase64: nonceBase64,
      aad: aad,
    );
    return utf8.decode(plainBytes);
  }
}
