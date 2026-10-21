import 'package:equatable/equatable.dart';

import '../models/pairing_session_model.dart';

/// Kết quả phân tích một chuỗi QR / deeplink thô.
sealed class QrLink extends Equatable {
  const QrLink();
}

/// Universal Opaque QR (ROADMAP_DEEPLINK_QR_V2 v3.3): chỉ mang `code`.
class OpaqueQrLink extends QrLink {
  final String code;

  const OpaqueQrLink(this.code);

  @override
  List<Object?> get props => [code];
}

/// Invite v4 `smsnavigator://pair?v=4&…` — chỉ còn trong giai đoạn chuyển
/// tiếp (QR do app Owner bản cũ sinh ra). Gỡ ở roadmap GĐ6.
class LegacyInviteLink extends QrLink {
  final String raw;

  const LegacyInviteLink(this.raw);

  @override
  List<Object?> get props => [raw];
}

/// Parser thuần (không I/O) cho mọi nguồn mã: camera, ảnh, deeplink, dán tay.
///
/// Nhận:
/// - `https://<host được phép>/qr/<code>` (App Links / Universal Links);
/// - `smsnavigator://qr?code=<code>`;
/// - `<code>` trần (22 ký tự base64url) khi người dùng dán / nhập tay;
/// - invite v4 (chuyển tiếp).
///
/// Link https chỉ được chấp nhận khi host nằm trong [allowedHosts] — chặn mã
/// trỏ tới domain giả mạo. Khi [allowedHosts] rỗng (ví dụ validator của
/// scanner chỉ cần kiểm tra cấu trúc), mọi host đều qua bước cấu trúc.
abstract final class QrLinkParser {
  static final RegExp codePattern = RegExp(r'^[A-Za-z0-9_-]{22}$');

  static const String customScheme = 'smsnavigator';
  static const String qrHost = 'qr';
  static const String httpsPathSegment = 'qr';

  static QrLink? parse(String raw, {Set<String> allowedHosts = const {}}) {
    final value = raw.trim();
    if (value.isEmpty) return null;

    if (codePattern.hasMatch(value)) return OpaqueQrLink(value);

    final uri = Uri.tryParse(value);
    if (uri == null) return null;

    if (uri.scheme == customScheme && uri.host == qrHost) {
      final code = uri.queryParameters['code'] ?? '';
      return codePattern.hasMatch(code) ? OpaqueQrLink(code) : null;
    }

    if (uri.scheme == 'https') {
      final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
      if (segments.length != 2 || segments.first != httpsPathSegment) return null;
      if (allowedHosts.isNotEmpty && !allowedHosts.contains(uri.host.toLowerCase())) {
        return null;
      }
      final code = segments[1];
      return codePattern.hasMatch(code) ? OpaqueQrLink(code) : null;
    }

    if (InvitePayload.tryParse(value) != null) return LegacyInviteLink(value);

    return null;
  }

  /// Host (chữ thường) của một base URL; null nếu không parse được.
  static String? hostOf(String? baseUrl) {
    if (baseUrl == null || baseUrl.trim().isEmpty) return null;
    final host = Uri.tryParse(baseUrl.trim())?.host ?? '';
    return host.isEmpty ? null : host.toLowerCase();
  }
}
