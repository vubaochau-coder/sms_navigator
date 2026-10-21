import '../models/pairing_request_model.dart';
import '../models/qr_resolution.dart';

/// Use case Universal Opaque QR (roadmap v3.3).
abstract class QrRepository {
  /// Host được phép cho link `https://<host>/qr/<code>` (host server đang dùng).
  Future<Set<String>> allowedLinkHosts();

  /// Giải mã code → nghiệp vụ. Lỗi server được ném nguyên dạng `ApiException`.
  Future<QrResolution> resolve(String code);

  /// Gửi yêu cầu tham gia kênh bằng code (không cần pairing token).
  Future<ClaimRequestResultModel> claimPairing({
    required String code,
    required String deviceName,
  });
}
