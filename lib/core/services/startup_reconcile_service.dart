/// Reconcile lúc mở app (SRD 7.3) — hành vi ngầm, không có màn hình riêng:
/// 1. Đảm bảo identity key + thiết bị đã đăng ký (feature 1.1);
/// 2. Channel state: với mỗi kênh đang ACTIVE → provision envelope mới nhất
///    nếu thiếu (fetch key-envelope latest → unwrap → persist);
/// 3. Request state: join request APPROVED chưa provision → provision ngay;
/// 4. REVOKED (server loại kênh khỏi danh sách) → purge key material (KL12).
abstract class StartupReconcileService {
  Future<void> reconcile();
}
