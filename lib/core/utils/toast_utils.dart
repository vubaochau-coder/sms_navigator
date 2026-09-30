import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';

/// Kiểu thông báo Toast/SnackBar
enum ToastType { success, error, warning, info }

/// Tiện ích hiển thị thông báo Toast / SnackBar và Clipboard.
class ToastUtils {
  ToastUtils._();

  /// Hiển thị thông báo Toast / SnackBar nổi dạng Soft Modern
  static void showToast(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    Color bgColor;
    Color fgColor;
    IconData iconData;

    switch (type) {
      case ToastType.success:
        bgColor = AppColors.success;
        fgColor = Colors.white;
        iconData = Icons.check_circle_rounded;
        break;
      case ToastType.error:
        bgColor = AppColors.error;
        fgColor = Colors.white;
        iconData = Icons.error_rounded;
        break;
      case ToastType.warning:
        bgColor = AppColors.warning;
        fgColor = Colors.black87;
        iconData = Icons.warning_amber_rounded;
        break;
      case ToastType.info:
        bgColor = AppColors.primary;
        fgColor = Colors.white;
        iconData = Icons.info_outline_rounded;
        break;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(iconData, color: fgColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: fgColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: duration,
        action: action,
        elevation: 4,
      ),
    );
  }

  /// Toast thành công
  static void showSuccess(BuildContext context, String message) {
    showToast(context, message, type: ToastType.success);
  }

  /// Toast thất bại / lỗi
  static void showError(BuildContext context, String message) {
    showToast(context, message, type: ToastType.error);
  }

  /// Toast cảnh báo
  static void showWarning(BuildContext context, String message) {
    showToast(context, message, type: ToastType.warning);
  }

  /// Toast thông tin
  static void showInfo(BuildContext context, String message) {
    showToast(context, message, type: ToastType.info);
  }

  /// Sao chép vào clipboard và hiện Toast báo thành công
  static Future<void> copyToClipboard(
    BuildContext context,
    String text, {
    String successMessage = 'Đã sao chép vào bộ nhớ tạm',
  }) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) {
      showSuccess(context, successMessage);
    }
  }
}
