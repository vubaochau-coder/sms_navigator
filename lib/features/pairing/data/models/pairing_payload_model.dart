import 'dart:convert';

import 'package:equatable/equatable.dart';

class PairingPayloadModel extends Equatable {
  final String pairId;
  final String sharedSecretBase64;
  final int createdAt;
  final int expiresAt;

  /// Giữ lại để tương thích ngược với code cũ tham chiếu trường `code`.
  final String code;

  const PairingPayloadModel({
    required this.pairId,
    required this.sharedSecretBase64,
    required this.createdAt,
    required this.expiresAt,
    this.code = '',
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch > expiresAt;

  PairingPayloadModel copyWith({
    String? pairId,
    String? sharedSecretBase64,
    int? createdAt,
    int? expiresAt,
    String? code,
  }) {
    return PairingPayloadModel(
      pairId: pairId ?? this.pairId,
      sharedSecretBase64: sharedSecretBase64 ?? this.sharedSecretBase64,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      code: code ?? this.code,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pairId': pairId,
      'code': code,
      'sharedSecretBase64': sharedSecretBase64,
      'secret': sharedSecretBase64,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
    };
  }

  factory PairingPayloadModel.fromMap(Map<String, dynamic> map) {
    return PairingPayloadModel(
      pairId: map['pairId']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      sharedSecretBase64:
          (map['sharedSecretBase64'] ?? map['secret'])?.toString() ?? '',
      createdAt: (map['createdAt'] is num)
          ? (map['createdAt'] as num).toInt()
          : 0,
      expiresAt: (map['expiresAt'] is num)
          ? (map['expiresAt'] as num).toInt()
          : 0,
    );
  }

  /// Xuất dữ liệu JSON nhúng vào mã QR ghép đôi.
  String toQrData() {
    return jsonEncode({
      'v': 1,
      'pairId': pairId,
      'secret': sharedSecretBase64,
      'exp': expiresAt,
    });
  }

  /// Parse dữ liệu JSON đọc được từ mã QR ghép đôi.
  factory PairingPayloadModel.fromQrData(String rawData) {
    final map = jsonDecode(rawData) as Map<String, dynamic>;
    final pairId = map['pairId']?.toString() ?? '';
    final secret = map['secret']?.toString() ?? '';
    final exp = (map['exp'] is num) ? (map['exp'] as num).toInt() : 0;
    if (pairId.isEmpty || secret.isEmpty) {
      throw const FormatException('Mã QR không đúng định dạng ghép đôi.');
    }
    return PairingPayloadModel(
      pairId: pairId,
      sharedSecretBase64: secret,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      expiresAt: exp,
    );
  }

  @override
  List<Object?> get props => [
    pairId,
    sharedSecretBase64,
    createdAt,
    expiresAt,
    code,
  ];
}
