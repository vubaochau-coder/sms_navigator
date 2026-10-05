import 'package:flutter/material.dart';

/// Single Source of Truth cho việc điều hướng và truy cập context toàn cục không cần BuildContext.
///
/// [AppNavigator.key] được gán trực tiếp vào [MaterialApp.navigatorKey] ngay từ gốc ứng dụng.
/// Mọi tiện ích (DialogUtils, BottomSheetUtils, ToastUtils...) hoặc background services
/// đều lấy state và context từ đây.
abstract final class AppNavigator {
  /// GlobalKey của Navigator gốc toàn ứng dụng.
  static final GlobalKey<NavigatorState> key = GlobalKey<NavigatorState>();

  /// Lấy [NavigatorState] an toàn (không ném Exception nếu chưa khởi tạo binding/test)
  static NavigatorState? get state {
    try {
      return key.currentState;
    } catch (_) {
      return null;
    }
  }

  /// Lấy [BuildContext] hiện tại từ Navigator gốc
  static BuildContext? get currentContext {
    try {
      return key.currentContext;
    } catch (_) {
      return null;
    }
  }

  /// Lấy [OverlayState] từ Navigator gốc để gắn các lớp phủ (Loading, Tooltip, Banner...)
  static OverlayState? get overlay => state?.overlay;
}
