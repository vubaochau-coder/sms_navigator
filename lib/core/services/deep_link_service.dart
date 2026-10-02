import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';

/// Bọc [AppLinks] để tầng trên phụ thuộc abstraction, dễ thay mock khi test.
///
/// GĐ3 - deep link ghép đôi: QR v3 là URL `smsnavigator://pair?...`, camera
/// hệ thống hoặc app quét của bên thứ ba mở thẳng app qua scheme này.
class DeepLinkService {
  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;

  StreamSubscription<Uri>? _subscription;
  final StreamController<Uri> _controller = StreamController<Uri>.broadcast();

  /// Deep link mở app, bao gồm cả cold start (app chết rồi được mở qua link).
  /// Trên nền tảng không hỗ trợ, trả về stream rỗng thay vì lỗi.
  Stream<Uri> get uriStream {
    _subscription ??= _appLinks.uriLinkStream.listen(
      _controller.add,
      onError: (Object e) {
        debugPrint('DeepLinkService stream error: $e');
      },
    );
    return _controller.stream;
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }
}
