/// Giai đoạn của luồng xác nhận tham gia kênh độc lập.
enum JoinPhase {
  /// Khởi tạo, chưa nhận preview.
  initial,

  /// Đã có preview (resolve ở `QrEntryPage`), hiển thị card thông tin kênh và thiết bị (read-only).
  ready,

  /// Đang gửi claim request lên server.
  claiming,

  /// Claim thành công (toast & pop).
  claimSuccess,

  /// Claim thất bại (hiển thị lỗi để user thử lại).
  claimFailed,
}
