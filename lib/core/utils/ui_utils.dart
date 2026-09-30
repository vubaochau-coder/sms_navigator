import 'package:flutter/material.dart';

import 'bottom_sheet_utils.dart';
import 'dialog_utils.dart';
import 'toast_utils.dart';

export 'bottom_sheet_utils.dart';
export 'dialog_utils.dart';
export 'toast_utils.dart';

/// Facade tổng hợp tiện ích giao diện: Toast, Dialog, BottomSheet.
class UiUtils {
  UiUtils._();

  /// Toast / SnackBar
  static void showToast(
    BuildContext context,
    String message, {
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
  }) => ToastUtils.showToast(
    context,
    message,
    type: type,
    duration: duration,
    action: action,
  );

  static void showSuccessToast(BuildContext context, String message) =>
      ToastUtils.showSuccess(context, message);

  static void showErrorToast(BuildContext context, String message) =>
      ToastUtils.showError(context, message);

  static void showWarningToast(BuildContext context, String message) =>
      ToastUtils.showWarning(context, message);

  static void showInfoToast(BuildContext context, String message) =>
      ToastUtils.showInfo(context, message);

  static Future<void> copyToClipboard(
    BuildContext context,
    String text, {
    String successMessage = 'Đã sao chép vào bộ nhớ tạm',
  }) =>
      ToastUtils.copyToClipboard(context, text, successMessage: successMessage);

  /// Dialog
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = 'Xác nhận',
    String cancelText = 'Hủy bỏ',
    bool isDestructive = false,
    IconData? icon,
  }) => DialogUtils.showConfirmDialog(
    context,
    title: title,
    message: message,
    confirmText: confirmText,
    cancelText: cancelText,
    isDestructive: isDestructive,
    icon: icon,
  );

  /// BottomSheet
  static Future<T?> showAppBottomSheet<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
  }) => BottomSheetUtils.showAppBottomSheet<T>(
    context,
    child: child,
    title: title,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
  );
}
