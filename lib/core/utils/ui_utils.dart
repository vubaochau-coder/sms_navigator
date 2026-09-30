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

  /// Toast / SnackBar (không bắt buộc context)
  static void showToast(
    String message, {
    BuildContext? context,
    ToastType type = ToastType.info,
    Duration duration = const Duration(seconds: 3),
    String? title,
  }) => ToastUtils.showToast(
    message,
    context: context,
    type: type,
    duration: duration,
    title: title,
  );

  static void showSuccessToast(
    String message, {
    BuildContext? context,
    String? title,
  }) => ToastUtils.showSuccess(message, context: context, title: title);

  static void showErrorToast(
    String message, {
    BuildContext? context,
    String? title,
  }) => ToastUtils.showError(message, context: context, title: title);

  static void showWarningToast(
    String message, {
    BuildContext? context,
    String? title,
  }) => ToastUtils.showWarning(message, context: context, title: title);

  static void showInfoToast(
    String message, {
    BuildContext? context,
    String? title,
  }) => ToastUtils.showInfo(message, context: context, title: title);

  static Future<void> copyToClipboard(
    String text, {
    BuildContext? context,
    String successMessage = 'Đã sao chép vào bộ nhớ tạm',
  }) => ToastUtils.copyToClipboard(
    text,
    context: context,
    successMessage: successMessage,
  );

  /// Dialog
  static Future<T?> showBaseForm<T>(
    Widget child, {
    BuildContext? context,
    bool barrierDismissible = true,
    Color? barrierColor,
    EdgeInsets? customInsetPadding,
    bool useSafeArea = true,
  }) => DialogUtils.showBaseForm<T>(
    child,
    context: context,
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor,
    customInsetPadding: customInsetPadding,
    useSafeArea: useSafeArea,
  );

  static Future<bool> showInfoDialog({
    BuildContext? context,
    required String title,
    required String message,
    String buttonText = 'Đóng',
    IconData? icon,
    bool isMandatory = false,
    EdgeInsets? customInsetPadding,
  }) => DialogUtils.showInfoDialog(
    context: context,
    title: title,
    message: message,
    buttonText: buttonText,
    icon: icon,
    isMandatory: isMandatory,
    customInsetPadding: customInsetPadding,
  );

  static Future<bool?> showTwoOptionsDialog({
    BuildContext? context,
    required String title,
    required String message,
    String positiveText = 'Xác nhận',
    String negativeText = 'Hủy',
    bool isPositiveDestructive = false,
    bool swapButtonPositions = false,
    bool isMandatory = false,
    IconData? icon,
    EdgeInsets? customInsetPadding,
  }) => DialogUtils.showTwoOptionsDialog(
    context: context,
    title: title,
    message: message,
    positiveText: positiveText,
    negativeText: negativeText,
    isPositiveDestructive: isPositiveDestructive,
    swapButtonPositions: swapButtonPositions,
    isMandatory: isMandatory,
    icon: icon,
    customInsetPadding: customInsetPadding,
  );

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
  static Future<T?> showBottomSheetBaseForm<T>(
    Widget child, {
    BuildContext? context,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
    bool showDragHandle = true,
  }) => BottomSheetUtils.showBaseForm<T>(
    child,
    context: context,
    title: title,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: backgroundColor,
    showDragHandle: showDragHandle,
  );

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
