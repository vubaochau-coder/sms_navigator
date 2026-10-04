import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Dịch vụ quản lý giám sát lỗi Crashlytics tập trung.
/// Tự động bắt lỗi Fatal và Non-fatal, có cơ chế an toàn khi chạy Unit Test và khi offline.
class CrashlyticsService {
  static final CrashlyticsService instance = CrashlyticsService._internal();

  CrashlyticsService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Khởi tạo tích hợp Crashlytics với Flutter framework và PlatformDispatcher.
  /// Đảm bảo luôn hook bắt lỗi dù Firebase có khả dụng hay không.
  Future<void> initialize() async {
    // 1. Luôn hook bắt lỗi UI layout/rendering từ Flutter framework
    FlutterError.onError = (FlutterErrorDetails details) {
      if (kDebugMode) {
        FlutterError.dumpErrorToConsole(details);
      }
      if (Firebase.apps.isNotEmpty) {
        try {
          FirebaseCrashlytics.instance.recordFlutterFatalError(details);
        } catch (_) {}
      } else {
        debugPrint('💥 [FlutterError]: ${details.exceptionAsString()}\n${details.stack}');
      }
    };

    // 2. Luôn hook bắt toàn bộ lỗi async unhandled từ Dart runtime / PlatformDispatcher
    PlatformDispatcher.instance.onError = (error, stack) {
      recordError(error, stack, fatal: true);
      return true;
    };

    // 3. Kích hoạt FirebaseCrashlytics nếu Firebase đã khởi tạo
    try {
      if (Firebase.apps.isNotEmpty) {
        final crashlytics = FirebaseCrashlytics.instance;
        await crashlytics.setCrashlyticsCollectionEnabled(true);
        _isInitialized = true;
        debugPrint('CrashlyticsService initialized successfully.');
      } else {
        debugPrint('CrashlyticsService: Firebase not initialized, running in fallback local logger.');
      }
    } catch (e) {
      debugPrint('CrashlyticsService initialization error: $e');
    }
  }

  /// Ghi nhận lỗi có chủ đích (Non-fatal hoặc Fatal)
  Future<void> recordError(
    dynamic error,
    StackTrace? stack, {
    dynamic reason,
    Iterable<Object> information = const [],
    bool fatal = false,
  }) async {
    try {
      if (Firebase.apps.isEmpty) {
        debugPrint('💥 [Crashlytics Fallback Error] reason: $reason | error: $error\n$stack');
        return;
      }
      await FirebaseCrashlytics.instance.recordError(
        error,
        stack,
        reason: reason,
        information: information,
        fatal: fatal,
      );
    } catch (e) {
      debugPrint('CrashlyticsService.recordError failed: $e');
    }
  }

  /// Ghi nhật ký tiến trình (breadcrumb log) hỗ trợ tái hiện crash
  Future<void> log(String message) async {
    try {
      if (Firebase.apps.isEmpty) {
        if (kDebugMode) {
          debugPrint('📝 [Breadcrumb]: $message');
        }
        return;
      }
      await FirebaseCrashlytics.instance.log(message);
    } catch (_) {}
  }

  /// Gắn metadata tùy chỉnh (ví dụ: device_role, current_channel_id, epoch)
  Future<void> setCustomKey(String key, Object value) async {
    try {
      if (Firebase.apps.isEmpty) return;
      await FirebaseCrashlytics.instance.setCustomKey(key, value);
    } catch (_) {}
  }

  /// Gắn User / Device identifier
  Future<void> setUserId(String identifier) async {
    try {
      if (Firebase.apps.isEmpty) return;
      await FirebaseCrashlytics.instance.setUserIdentifier(identifier);
    } catch (_) {}
  }
}
