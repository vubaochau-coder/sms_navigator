import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../../../../core/utils/data_converter.dart';

/// Phiên ghép đôi - giao thức QR v3 (ECDH).
///
/// QR KHÔNG còn chứa shared secret. Nó chỉ mang:
/// - `k`: one-time pairing key do máy chủ cấp (bằng chứng sở hữu QR).
/// - `a`: X25519 public key của Máy A (máy B dùng để derive key; đối chiếu
///   với `sender_pubkey` máy chủ trả về để phát hiện key-swap).
/// - `e`: thời điểm hết hạn (epoch ms, cửa sổ 10 phút).
///
/// Shared secret được hai máy tự derive bằng ECDH + HKDF sau khi confirm;
/// máy chủ chỉ làm trung gian public key (blind relay).
class PairingPayloadModel extends Equatable {
  final String pairId;
  final String pairingKey;

  /// X25519 public key (Base64) của Máy A — nằm trong QR.
  final String senderPubkey;

  /// X25519 private key (Base64) của Máy A — CHỈ tồn tại trong RAM của Máy A,
  /// không bao giờ nằm trong QR hay trên mạng.
  final String senderPrivateKeyBase64;

  /// Shared secret AES-256 (Base64). Máy A trống cho tới khi link thành công;
  /// Máy B có giá trị ngay sau confirm.
  final String sharedSecretBase64;

  final int createdAt;
  final int expiresAt;

  const PairingPayloadModel({
    required this.pairId,
    required this.pairingKey,
    this.senderPubkey = '',
    this.senderPrivateKeyBase64 = '',
    this.sharedSecretBase64 = '',
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;

  PairingPayloadModel copyWith({
    String? pairId,
    String? pairingKey,
    String? senderPubkey,
    String? senderPrivateKeyBase64,
    String? sharedSecretBase64,
    int? createdAt,
    int? expiresAt,
  }) {
    return PairingPayloadModel(
      pairId: pairId ?? this.pairId,
      pairingKey: pairingKey ?? this.pairingKey,
      senderPubkey: senderPubkey ?? this.senderPubkey,
      senderPrivateKeyBase64:
          senderPrivateKeyBase64 ?? this.senderPrivateKeyBase64,
      sharedSecretBase64: sharedSecretBase64 ?? this.sharedSecretBase64,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pairId': pairId,
      'pairingKey': pairingKey,
      'senderPubkey': senderPubkey,
      'sharedSecretBase64': sharedSecretBase64,
      'secret': sharedSecretBase64,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
    };
  }

  factory PairingPayloadModel.fromMap(Map<String, dynamic> map) {
    return PairingPayloadModel(
      pairId: DataConverter.cvToString(map['pairId'], '')!,
      pairingKey: DataConverter.cvToString(map['pairingKey'], '')!,
      senderPubkey: DataConverter.cvToString(map['senderPubkey'], '')!,
      sharedSecretBase64: DataConverter.cvToString(
        map['sharedSecretBase64'] ?? map['secret'],
        '',
      )!,
      createdAt: DataConverter.cvToInt(map['createdAt'], 0)!,
      expiresAt: DataConverter.cvToInt(map['expiresAt'], 0)!,
    );
  }

  /// Xuất dữ liệu JSON nhúng vào mã QR ghép đôi (giao thức v3 - ECDH).
  String toQrData() {
    return jsonEncode({
      'v': 3,
      'k': pairingKey,
      'a': senderPubkey,
      'e': expiresAt,
    });
  }

  /// Parse dữ liệu JSON đọc được từ mã QR ghép đôi (chỉ nhận giao thức v3).
  factory PairingPayloadModel.fromQrData(String rawData) {
    final Object? decoded;
    try {
      decoded = jsonDecode(rawData);
    } on FormatException {
      rethrow;
    }
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Mã QR không đúng định dạng ghép đôi.');
    }
    if (!_isPairingQrMap(decoded)) {
      throw const FormatException('Mã QR không đúng định dạng ghép đôi.');
    }
    final map = decoded;
    return PairingPayloadModel(
      pairId: '',
      pairingKey: map['k'] as String,
      senderPubkey: map['a'] as String,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      expiresAt: DataConverter.cvToInt(map['e'], 0)!,
    );
  }

  /// Kiểm tra nhanh payload thô (từ camera/ảnh/deep link) có phải QR ghép
  /// đôi giao thức v3 hay không - dùng bởi QrScanHandlerRegistry.
  static bool looksLikePairingQr(String rawData) {
    final Object? decoded;
    try {
      decoded = jsonDecode(rawData);
    } on FormatException {
      return false;
    }
    return decoded is Map<String, dynamic> && _isPairingQrMap(decoded);
  }

  static bool _isPairingQrMap(Map<String, dynamic> map) {
    if (map['v'] != 3) return false;
    final key = map['k'];
    final senderPubkey = map['a'];
    return key is String &&
        key.isNotEmpty &&
        senderPubkey is String &&
        senderPubkey.isNotEmpty;
  }

  @override
  List<Object?> get props => [
    pairId,
    pairingKey,
    senderPubkey,
    senderPrivateKeyBase64,
    sharedSecretBase64,
    createdAt,
    expiresAt,
  ];
}
