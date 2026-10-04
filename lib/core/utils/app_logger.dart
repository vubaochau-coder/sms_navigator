import 'package:flutter/foundation.dart';

import '../services/crashlytics_service.dart';

/// Trình ghi log ứng dụng tập trung, tự động báo cáo warning và error
/// lên Crashlytics service để hỗ trợ điều tra sự cố.
class AppLogger {
  static final CrashlyticsService _crashlytics = CrashlyticsService.instance;

  /// Log thông tin debug chỉ hiển thị ở debug mode
  static void d(String tag, String message) {
    if (kDebugMode) {
      debugPrint('🔍 [DEBUG] [$tag] $message');
    }
  }

  /// Log thông tin tiến trình và ghi breadcrumb
  static void i(String tag, String message) {
    debugPrint('ℹ️ [INFO] [$tag] $message');
    _crashlytics.log('[$tag] $message');
  }

  /// Log cảnh báo sự cố bất thường (không làm crash app)
  static void w(
    String tag,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    debugPrint('⚠️ [WARN] [$tag] $message ${error != null ? ': $error' : ''}');
    _crashlytics.log('[WARN] [$tag] $message');
    if (error != null) {
      _crashlytics.recordError(
        error,
        stackTrace,
        reason: '[$tag] $message',
        fatal: false,
      );
    }
  }

  /// Log lỗi nghiêm trọng hoặc ngoại lệ không mong muốn
  static void e(
    String tag,
    String message,
    Object error, [
    StackTrace? stackTrace,
  ]) {
    debugPrint('💥 [ERROR] [$tag] $message: $error\n${stackTrace ?? ''}');
    _crashlytics.recordError(
      error,
      stackTrace ?? StackTrace.current,
      reason: '[$tag] $message',
      fatal: false,
    );
  }
}
