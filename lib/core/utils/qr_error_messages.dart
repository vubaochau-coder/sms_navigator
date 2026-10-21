import '../errors/app_exceptions.dart';
import '../l10n/app_l10n.dart';

/// Thông điệp lỗi QR / lời mời dùng chung cho mọi màn hình (l10n).
abstract final class QrErrorMessages {
  static String get unsupportedFormat => AppL10n.current.qrUnsupportedFormat;
  static String get updateRequired => AppL10n.current.qrUpdateRequired;

  static String? codeOf(Object error) => error is ApiException ? error.errorCode : null;

  /// Thông điệp cho mã lỗi server đã biết; `null` nếu không nhận ra.
  static String? forCode(String? code) {
    final l10n = AppL10n.current;
    switch (code) {
      case 'REQUEST_ALREADY_PENDING':
        return l10n.joinErrorAlreadyPending;
      case 'ALREADY_MEMBER':
        return l10n.joinErrorAlreadyMember;
      case 'QR_EXPIRED':
        return l10n.joinErrorExpired;
      case 'QR_ALREADY_USED':
        return l10n.joinErrorUsed;
      case 'CHANNEL_NOT_ACTIVE':
        return l10n.joinErrorChannelArchived;
      case 'NOT_FOUND':
        return l10n.qrNotFound;
      case 'UNSUPPORTED_QR_TYPE':
        return l10n.qrUpdateRequired;
      case 'RATE_LIMITED':
        return l10n.qrRateLimited;
    }
    return null;
  }

  static String forError(Object error, {String? fallback}) {
    final byCode = forCode(codeOf(error));
    if (byCode != null) return byCode;
    if (error is NetworkException) return AppL10n.current.networkOffline;
    return fallback ?? AppL10n.current.qrCheckFailed;
  }
}
