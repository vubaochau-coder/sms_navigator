/// Giai đoạn của luồng xác nhận tham gia kênh độc lập.
enum JoinPhase {
  /// Khởi tạo, chưa resolve session.
  initial,

  /// Đang gọi API resolve để lấy thông tin kênh (hiển thị skeleton).
  resolving,

  /// Resolve thất bại (lỗi kết nối, hết hạn, ALREADY_MEMBER, REQUEST_ALREADY_PENDING...).
  resolveFailed,

  /// Đã resolve thành công, hiển thị card thông tin kênh và thiết bị (read-only).
  ready,

  /// Đang gửi claim request lên server.
  claiming,

  /// Claim thành công (toast & pop).
  claimSuccess,

  /// Claim thất bại (hiển thị lỗi để user thử lại).
  claimFailed,
}
