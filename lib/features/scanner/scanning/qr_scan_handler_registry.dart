import 'package:flutter/widgets.dart';

import 'qr_scan_handler.dart';

/// Điều phối payload QR tới handler nghiệp vụ đầu tiên nhận diện được.
///
/// Scanner page không biết gì về nghiệp vụ cụ thể - thêm loại QR mới chỉ
/// cần đăng ký thêm một [QrScanHandler].
class QrScanHandlerRegistry {
  const QrScanHandlerRegistry({required List<QrScanHandler> handlers})
      : _handlers = handlers;

  final List<QrScanHandler> _handlers;

  /// Trả về true nếu có handler nhận diện được payload.
  bool route(BuildContext context, QrScanFlow flow, String raw) {
    for (final handler in _handlers) {
      if (handler.canHandle(raw)) {
        handler.handleScan(context, flow, raw);
        return true;
      }
    }
    return false;
  }

  void dispose() {
    for (final handler in _handlers) {
      handler.dispose();
    }
  }
}
