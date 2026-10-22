import 'package:equatable/equatable.dart';

import '../utils/data_converter.dart';

/// Phiên mời QR vừa tạo — `POST /api/v2/channels/sessions` (API spec §4.5).
/// TTL 10 phút, single-use.
///
/// [code] / [qrUrl]: Universal Opaque QR (roadmap v3.3) — link in vào QR.
/// (Trường v4 `pairing_token` / `invite_url` đã gỡ ở roadmap GĐ6.)
class PairingSessionModel extends Equatable {
  final String sessionId;
  final String expiresAt;
  final String code;
  final String qrUrl;
  final DateTime? createdAt;

  const PairingSessionModel({
    required this.sessionId,
    required this.expiresAt,
    this.code = '',
    this.qrUrl = '',
    this.createdAt,
  });

  /// Link để render QR / chia sẻ.
  String get shareUrl => qrUrl;

  DateTime get effectiveCreatedAt =>
      createdAt ??
      (DateTime.tryParse(expiresAt)?.subtract(const Duration(minutes: 10)) ??
          DateTime.fromMillisecondsSinceEpoch(0));

  bool get isExpired {
    final deadline = DateTime.tryParse(expiresAt);
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline);
  }

  factory PairingSessionModel.fromMap(Map<String, dynamic> map) {
    final expiresAt = DataConverter.cvToString(map['expires_at'], '')!;
    return PairingSessionModel(
      sessionId: DataConverter.cvToString(map['session_id'], '')!,
      expiresAt: expiresAt,
      code: DataConverter.cvToString(map['code'], '')!,
      qrUrl: DataConverter.cvToString(map['qr_url'], '')!,
      createdAt:
          DateTime.tryParse(expiresAt)?.subtract(const Duration(minutes: 10)),
    );
  }

  @override
  List<Object?> get props => [sessionId, expiresAt, code, qrUrl, createdAt];
}
