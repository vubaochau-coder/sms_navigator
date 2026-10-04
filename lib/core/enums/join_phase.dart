/// Giai đoạn của luồng tham gia kênh (3.1–3.6).
enum JoinPhase {
  /// Đang hiển thị dialog xác nhận (3.2) — KHÔNG tự gọi API sau khi quét.
  confirming,

  /// Đã gửi request, đang chờ Owner duyệt (3.4) — không phụ thuộc TTL 10'.
  waitingApproval,

  /// Được duyệt — app sẽ provision key ngầm rồi quay về màn kênh.
  approved,

  /// Bị từ chối / hủy / mã lỗi (3.6).
  failed,
}
