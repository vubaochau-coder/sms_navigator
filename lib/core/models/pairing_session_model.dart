import 'dart:convert';

import 'package:equatable/equatable.dart';

import '../utils/data_converter.dart';

/// Phiên mời QR vừa tạo — `POST /api/v2/channels/sessions` (API spec §4.5).
/// Server sinh sẵn [inviteUrl] format v4, TTL 10 phút, single-use.
class PairingSessionModel extends Equatable {
  final String sessionId;
  final String pairingToken;
  final String expiresAt;
  final String inviteUrl;

  const PairingSessionModel({
    required this.sessionId,
    required this.pairingToken,
    required this.expiresAt,
    required this.inviteUrl,
  });

  factory PairingSessionModel.fromMap(Map<String, dynamic> map) {
    return PairingSessionModel(
      sessionId: DataConverter.cvToString(map['session_id'], '')!,
      pairingToken: DataConverter.cvToString(map['pairing_token'], '')!,
      expiresAt: DataConverter.cvToString(map['expires_at'], '')!,
      inviteUrl: DataConverter.cvToString(map['invite_url'], '')!,
    );
  }

  @override
  List<Object?> get props => [sessionId, pairingToken, expiresAt, inviteUrl];
}

/// Invite URL v4 sau khi parse (SRD 3.4 — không chứa key/credential dài hạn):
/// `smsnavigator://pair?v=4&s=<sessionId>&t=<token>&u=<b64url(server)>&e=<expiryMs>`
class InvitePayload extends Equatable {
  static const int supportedVersion = 4;

  final String sessionId;
  final String pairingToken;
  final String serverBaseUrl;
  final int expiryEpochMs;

  const InvitePayload({
    required this.sessionId,
    required this.pairingToken,
    required this.serverBaseUrl,
    required this.expiryEpochMs,
  });

  bool get isExpired => DateTime.now().millisecondsSinceEpoch >= expiryEpochMs;

  /// Parse một invite URL/QR data v4; trả về null nếu sai format/version.
  static InvitePayload? tryParse(String raw) {
    final uri = Uri.tryParse(raw.trim());
    if (uri == null || uri.scheme != 'smsnavigator' || uri.host != 'pair') {
      return null;
    }
    if (uri.queryParameters['v'] != supportedVersion.toString()) {
      return null;
    }
    final sessionId = uri.queryParameters['s'] ?? '';
    final pairingToken = uri.queryParameters['t'] ?? '';
    final serverBase64Url = uri.queryParameters['u'] ?? '';
    final expiry = int.tryParse(uri.queryParameters['e'] ?? '');
    if (sessionId.isEmpty || pairingToken.isEmpty || expiry == null) {
      return null;
    }
    String serverUrl = '';
    if (serverBase64Url.isNotEmpty) {
      final normalized = base64UrlPadded(serverBase64Url);
      try {
        serverUrl = String.fromCharCodes(base64Decode(normalized));
      } on FormatException {
        serverUrl = '';
      }
    }
    return InvitePayload(
      sessionId: sessionId,
      pairingToken: pairingToken,
      serverBaseUrl: serverUrl,
      expiryEpochMs: expiry,
    );
  }

  /// base64url có thể thiếu padding — chuẩn hóa về base64 chuẩn trước khi decode.
  static String base64UrlPadded(String value) {
    final normalized = value.replaceAll('-', '+').replaceAll('_', '/');
    final remainder = normalized.length % 4;
    if (remainder == 0) return normalized;
    return '$normalized${'=' * (4 - remainder)}';
  }

  @override
  List<Object?> get props => [sessionId, pairingToken, serverBaseUrl, expiryEpochMs];
}
