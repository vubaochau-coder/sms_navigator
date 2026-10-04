import 'package:flutter/widgets.dart';

/// Điều khiển vòng đời một lần quét của màn hình scanner.
///
/// Scanner là thành phần trung tính: handler nghiệp vụ (pairing, whitelist...)
/// quyết định khi nào phiên quét kết thúc thông qua interface này.
abstract interface class QrScanFlow {
  /// Kết thúc phiên quét thành công - scanner tự đóng màn hình.
  void complete();

  /// Xử lý thất bại - scanner tạm dừng trong khoảng cooldown ngắn rồi
  /// cho phép quét mã tiếp theo.
  void fail();
}

/// Một handler xử lý một loại payload QR (ghép đôi, whitelist, cấu hình...).
///
/// Cài đặt handler phải idempotent và không giữ tham chiếu tới BuildContext
/// sau khi phiên quét kết thúc.
abstract interface class QrScanHandler {
  /// Payload thô đọc được từ camera/ảnh có thuộc loại này không.
  bool canHandle(String raw);

  /// Điều phối payload vào nghiệp vụ tương ứng.
  void handleScan(BuildContext context, QrScanFlow flow, String raw);

  /// Giải phóng tài nguyên (stream subscription, timer...) khi scanner đóng.
  void dispose() {}
}
