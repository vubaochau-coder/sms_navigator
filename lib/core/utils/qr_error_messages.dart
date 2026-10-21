import '../errors/app_exceptions.dart';

/// Thông điệp tiếng Việt cho lỗi QR / lời mời — dùng chung cho mọi màn hình.
abstract final class QrErrorMessages {
  static const String unsupportedFormat = 'Mã QR không được hỗ trợ. Hãy quét mã mời từ SMS Navigator.';
  static const String updateRequired = 'Mã này cần phiên bản SMS Navigator mới hơn. Hãy cập nhật ứng dụng.';

  static String? codeOf(Object error) => error is ApiException ? error.errorCode : null;

  static String forError(Object error, {String fallback = 'Không thể kiểm tra mã kết nối. Vui lòng thử lại sau.'}) {
    switch (codeOf(error)) {
      case 'REQUEST_ALREADY_PENDING':
        return 'Bạn đã có yêu cầu tham gia kênh này đang chờ duyệt.';
      case 'ALREADY_MEMBER':
        return 'Thiết bị của bạn đã là thành viên của kênh này.';
      case 'QR_EXPIRED':
        return 'Mã mời đã hết hạn. Hãy xin Chủ kênh một mã mời mới.';
      case 'QR_ALREADY_USED':
        return 'Mã mời đã được sử dụng. Hãy xin Chủ kênh một mã mời mới.';
      case 'CHANNEL_NOT_ACTIVE':
        return 'Kênh này đã bị lưu trữ, không thể tham gia.';
      case 'NOT_FOUND':
        return 'Không tìm thấy mã mời. Hãy kiểm tra lại hoặc xin Chủ kênh mã mới.';
      case 'UNSUPPORTED_QR_TYPE':
        return updateRequired;
      case 'RATE_LIMITED':
        return 'Bạn thử quá nhiều lần. Vui lòng đợi một lát rồi thử lại.';
    }
    if (error is NetworkException) return 'Không kết nối được máy chủ. Kiểm tra mạng và thử lại.';
    return fallback;
  }
}
