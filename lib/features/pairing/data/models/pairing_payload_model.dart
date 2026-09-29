import 'package:equatable/equatable.dart';

class PairingPayloadModel extends Equatable {
  final String pairId;
  final String code;
  final String sharedSecretBase64;
  final int createdAt;
  final int expiresAt;

  const PairingPayloadModel({
    required this.pairId,
    required this.code,
    required this.sharedSecretBase64,
    required this.createdAt,
    required this.expiresAt,
  });

  PairingPayloadModel copyWith({
    String? pairId,
    String? code,
    String? sharedSecretBase64,
    int? createdAt,
    int? expiresAt,
  }) {
    return PairingPayloadModel(
      pairId: pairId ?? this.pairId,
      code: code ?? this.code,
      sharedSecretBase64: sharedSecretBase64 ?? this.sharedSecretBase64,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pairId': pairId,
      'code': code,
      'sharedSecretBase64': sharedSecretBase64,
      'createdAt': createdAt,
      'expiresAt': expiresAt,
    };
  }

  factory PairingPayloadModel.fromMap(Map<String, dynamic> map) {
    return PairingPayloadModel(
      pairId: map['pairId']?.toString() ?? '',
      code: map['code']?.toString() ?? '',
      sharedSecretBase64: map['sharedSecretBase64']?.toString() ?? '',
      createdAt: (map['createdAt'] is num) ? (map['createdAt'] as num).toInt() : 0,
      expiresAt: (map['expiresAt'] is num) ? (map['expiresAt'] as num).toInt() : 0,
    );
  }

  @override
  List<Object?> get props => [pairId, code, sharedSecretBase64, createdAt, expiresAt];
}
