import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../../../../core/utils/data_converter.dart';

/// Phiên ghép đôi - giao thức QR v2.
///
/// QR chỉ mang cặp `[pairingKey, sharedSecret]` do máy chủ cấp/sinh ra;
/// `pairId` do máy chủ phát hành và KHÔNG nằm trong QR (máy B nhận pairId
/// từ response của /pair/confirm).
class PairingPayloadModel extends Equatable {
  final String pairId;
  final String pairingKey;
  final String sharedSecretBase64;
  final int createdAt;
  final int expiresAt;

  const PairingPayloadModel({
    required this.pairId,
    required this.pairingKey,
    required this.sharedSecretBase64,
    required this.createdAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;

  PairingPayloadModel copyWith({
    String? pairId,
    String? pairingKey,
    String? sharedSecretBase64,
    int? createdAt,
    int? expiresAt,
  }) {
    return PairingPayloadModel(
      pairId: pairId ?? this.pairId,
      pairingKey: pairingKey ?? this.pairingKey,
      sharedSecretBase64: sharedSecretBase64 ?? this.sharedSecretBase64,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pairId': pairId,
      'pairingKey': pairingKey,
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
      sharedSecretBase64: DataConverter.cvToString(
        map['sharedSecretBase64'] ?? map['secret'],
        '',
      )!,
      createdAt: DataConverter.cvToInt(map['createdAt'], 0)!,
      expiresAt: DataConverter.cvToInt(map['expiresAt'], 0)!,
    );
  }

  /// Xuất dữ liệu JSON nhúng vào mã QR ghép đôi (giao thức v2):
  /// - `k`: one-time pairing key do máy chủ cấp (bằng chứng sở hữu QR).
  /// - `s`: shared secret mã hoá nội dung OTP (E2E, máy chủ không biết).
  /// - `e`: thời điểm hết hạn (epoch ms, cửa sổ 10 phút).
  String toQrData() {
    return jsonEncode({
      'v': 2,
      'k': pairingKey,
      's': sharedSecretBase64,
      'e': expiresAt,
    });
  }

  /// Parse dữ liệu JSON đọc được từ mã QR ghép đôi (chỉ nhận giao thức v2).
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
      sharedSecretBase64: map['s'] as String,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      expiresAt: DataConverter.cvToInt(map['e'], 0)!,
    );
  }

  /// Kiểm tra nhanh payload thô (từ camera/ảnh/deep link) có phải QR ghép
  /// đôi giao thức v2 hay không - dùng bởi QrScanHandlerRegistry.
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
    if (map['v'] != 2) return false;
    final key = map['k'];
    final secret = map['s'];
    return key is String && key.isNotEmpty && secret is String && secret.isNotEmpty;
  }

  @override
  List<Object?> get props => [
    pairId,
    pairingKey,
    sharedSecretBase64,
    createdAt,
    expiresAt,
  ];
}
