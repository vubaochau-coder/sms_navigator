import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Dịch vụ quản lý giám sát lỗi Crashlytics tập trung.
/// Tự động bắt lỗi Fatal và Non-fatal, có cơ chế an toàn khi chạy Unit Test.
class CrashlyticsService {
  static final CrashlyticsService instance = CrashlyticsService._internal();

  CrashlyticsService._internal();

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  /// Khởi tạo tích hợp Crashlytics với Flutter framework và PlatformDispatcher
  Future<void> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        debugPrint(
          'CrashlyticsService: Firebase not initialized, skipping setup.',
        );
        return;
      }

      final crashlytics = FirebaseCrashlytics.instance;

      // Trong chế độ release, thu thập crash report đầy đủ
      // Trong debug mode, có thể bật nếu cần kiểm thử crashlytics
      await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

      // Bắt toàn bộ lỗi Flutter framework (UI layout, render, widget errors)
      FlutterError.onError = (FlutterErrorDetails details) {
        if (kDebugMode) {
          FlutterError.dumpErrorToConsole(details);
        }
        crashlytics.recordFlutterFatalError(details);
      };

      // Bắt toàn bộ lỗi async unhandled từ Dart runtime / PlatformDispatcher
      PlatformDispatcher.instance.onError = (error, stack) {
        recordError(error, stack, fatal: true);
        return true;
      };

      _isInitialized = true;
      debugPrint('CrashlyticsService initialized successfully.');
    } catch (e) {
      debugPrint('CrashlyticsService initialization failed: $e');
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
        debugPrint('CrashlyticsService [Offline Error]: $error\n$stack');
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
      if (Firebase.apps.isEmpty) return;
      await FirebaseCrashlytics.instance.log(message);
    } catch (_) {}
  }

  /// Gắn metadata tùy chỉnh (ví dụ: device_role, current_pair_id, relay_mode)
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
