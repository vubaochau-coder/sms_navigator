/// Lớp nền cho toàn bộ exception nghiệp vụ của ứng dụng.
class AppException implements Exception {
  final String message;

  const AppException(this.message);

  @override
  String toString() => message;
}

/// Lỗi kết nối mạng: không truy cập được server, timeout, DNS...
class NetworkException extends AppException {
  const NetworkException(super.message);
}

/// Lỗi trả về từ REST API (mã trạng thái ngoài 2xx, payload sai định dạng...).
class ApiException extends AppException {
  final int? statusCode;

  const ApiException(super.message, {this.statusCode});
}

/// Lỗi xác thực: thiếu hoặc sai device token (HTTP 401).
class UnauthorizedException extends AppException {
  const UnauthorizedException(super.message);
}
