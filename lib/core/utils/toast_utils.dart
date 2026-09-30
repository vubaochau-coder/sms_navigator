import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';

import '../constants/app_colors.dart';

/// Kiểu thông báo Toast
enum ToastType { success, error, warning, info }

/// Tiện ích hiển thị thông báo Toast sử dụng package toastification.
/// Cho phép gọi trực tiếp từ BLoC hoặc bất cứ đâu mà không cần BuildContext.
class ToastUtils {
  ToastUtils._();

  /// Hiển thị Toast thông báo (không bắt buộc context)
  static void showToast(
    String message, {
    BuildContext? context,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    String? title,
  }) {
    try {
      ToastificationType toastType;
      Color primaryColor;
      IconData iconData;

      switch (type) {
        case ToastType.success:
          toastType = ToastificationType.success;
          primaryColor = AppColors.success;
          iconData = Icons.check_circle_rounded;
          break;
        case ToastType.error:
          toastType = ToastificationType.error;
          primaryColor = AppColors.error;
          iconData = Icons.error_rounded;
          break;
        case ToastType.warning:
          toastType = ToastificationType.warning;
          primaryColor = AppColors.warning;
          iconData = Icons.warning_amber_rounded;
          break;
        case ToastType.info:
          toastType = ToastificationType.info;
          primaryColor = AppColors.primary;
          iconData = Icons.info_outline_rounded;
          break;
      }

      toastification.show(
        context: context,
        type: toastType,
        style: ToastificationStyle.flatColored,
        autoCloseDuration: duration,
        title: title != null
            ? Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              )
            : null,
        description: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        ),
        alignment: Alignment.bottomCenter,
        direction: TextDirection.ltr,
        animationDuration: const Duration(milliseconds: 300),
        icon: Icon(iconData, color: primaryColor, size: 20),
        primaryColor: primaryColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
        showProgressBar: false,
        closeButton: const ToastCloseButton(showType: CloseButtonShowType.none),
        dragToClose: true,
      );
    } catch (e) {
      debugPrint(
        'ToastUtils: Toastification is not available or UI not mounted: $e',
      );
    }
  }

  /// Toast thành công
  static void showSuccess(
    String message, {
    BuildContext? context,
    String? title,
  }) {
    showToast(message, context: context, type: ToastType.success, title: title);
  }

  /// Toast thất bại / lỗi
  static void showError(
    String message, {
    BuildContext? context,
    String? title,
  }) {
    showToast(message, context: context, type: ToastType.error, title: title);
  }

  /// Toast cảnh báo
  static void showWarning(
    String message, {
    BuildContext? context,
    String? title,
  }) {
    showToast(message, context: context, type: ToastType.warning, title: title);
  }

  /// Toast thông tin
  static void showInfo(String message, {BuildContext? context, String? title}) {
    showToast(message, context: context, type: ToastType.info, title: title);
  }

  /// Sao chép vào clipboard và hiện Toast báo thành công (không bắt buộc context)
  static Future<void> copyToClipboard(
    String text, {
    BuildContext? context,
    String successMessage = 'Đã sao chép vào bộ nhớ tạm',
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    showSuccess(successMessage);
  }
}
