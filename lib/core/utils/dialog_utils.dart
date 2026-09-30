import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Tiện ích hiển thị Dialog / Alert thống nhất cho toàn bộ dự án
class DialogUtils {
  DialogUtils._();

  /// Navigator key toàn cục dùng cho các trường hợp gọi dialog không truyền context
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  // ==========================================
  // HẰNG SỐ GIAO DIỆN CHUẨN (UI TOKENS)
  // ==========================================
  static const double borderRadiusValue = 16.0;
  static const BorderRadius borderRadius = BorderRadius.all(
    Radius.circular(borderRadiusValue),
  );
  static const double buttonRadiusValue = 8.0;
  static const BorderRadius buttonBorderRadius = BorderRadius.all(
    Radius.circular(buttonRadiusValue),
  );

  static const double iconSize = 24.0;
  static const double iconSpacing = 8.0;
  static const double titleFontSize = 17.0;
  static const double messageFontSize = 14.0;
  static const double messageLineHeight = 1.4;

  /// Inset padding chuẩn: giảm khoảng cách tới 4 mép màn hình xuống 12dp
  static const EdgeInsets insetPadding = EdgeInsets.all(12.0);
  static const String defaultConfirmText = 'Xác nhận';
  static const String defaultCancelText = 'Hủy bỏ';
  static const String defaultCloseText = 'Đóng';

  /// Helper lấy BuildContext an toàn từ tham số hoặc [navigatorKey]
  static BuildContext _resolveContext(BuildContext? context) {
    final ctx = context ?? navigatorKey.currentContext;
    if (ctx == null) {
      throw StateError(
        'Không tìm thấy BuildContext để hiển thị Dialog. Hãy truyền context hoặc cài đặt navigatorKey trong MaterialApp.',
      );
    }
    return ctx;
  }

  /// Hiển thị container Dialog chuẩn dự án cho nội dung tùy biến (custom content).
  ///
  /// [child]: Widget nội dung bên trong dialog (tham số bắt buộc).
  /// Cung cấp sẵn khung chuẩn: bo góc [borderRadius], insetPadding 12dp ở 4 hướng,
  /// màu nền [ColorScheme.surface], clip antiAlias.
  static Future<T?> showBaseForm<T>(
    Widget child, {
    BuildContext? context,
    bool barrierDismissible = true,
    Color? barrierColor,
    EdgeInsets? customInsetPadding,
    bool useSafeArea = true,
  }) {
    final ctx = _resolveContext(context);
    return showDialog<T>(
      context: ctx,
      barrierDismissible: barrierDismissible,
      barrierColor: barrierColor,
      useSafeArea: useSafeArea,
      builder: (dialogContext) {
        if (child is Dialog || child is AlertDialog) {
          return child;
        }
        return Dialog(
          backgroundColor: Theme.of(dialogContext).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          shape: const RoundedRectangleBorder(borderRadius: borderRadius),
          insetPadding: customInsetPadding ?? insetPadding,
          clipBehavior: Clip.antiAlias,
          child: child,
        );
      },
    );
  }

  /// Hộp thoại thông báo (chỉ có 1 nút để đóng).
  ///
  /// - [isMandatory]: Nếu true, người dùng bắt buộc phải nhấn nút để đóng
  ///   (không thể tap ra ngoài vùng dialog hoặc bấm nút Back để đóng).
  static Future<bool> showInfoDialog({
    BuildContext? context,
    required String title,
    required String message,
    String buttonText = defaultCloseText,
    IconData? icon,
    bool isMandatory = false,
    EdgeInsets? customInsetPadding,
  }) async {
    final ctx = _resolveContext(context);

    final result = await showDialog<bool>(
      context: ctx,
      barrierDismissible: !isMandatory,
      builder: (dialogContext) {
        return PopScope(
          canPop: !isMandatory,
          child: AlertDialog(
            shape: const RoundedRectangleBorder(borderRadius: borderRadius),
            insetPadding: customInsetPadding ?? insetPadding,
            title: Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, color: AppColors.primary, size: iconSize),
                  const SizedBox(width: iconSpacing),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: TextStyle(
                fontSize: messageFontSize,
                color: Theme.of(
                  dialogContext,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
                height: messageLineHeight,
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                    borderRadius: buttonBorderRadius,
                  ),
                  elevation: 0,
                ),
                onPressed: () => Navigator.of(dialogContext).pop(true),
                child: Text(
                  buttonText,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );

    return result ?? false;
  }

  /// Hộp thoại 2 lựa chọn (Negative & Positive).
  ///
  /// - Trả về `true` khi chọn nút Positive.
  /// - Trả về `false` khi chọn nút Negative.
  /// - Trả về `null` khi bị đóng ngoài ý muốn (tap ra ngoài hoặc bấm back) nếu [isMandatory] = false.
  /// - [swapButtonPositions]: Nếu true, hoán đổi vị trí của Positive (trái) và Negative (phải).
  /// - [isMandatory]: Nếu true, bắt buộc người dùng phải chọn 1 trong 2 nút (không thể trả về null).
  static Future<bool?> showTwoOptionsDialog({
    BuildContext? context,
    required String title,
    required String message,
    String positiveText = defaultConfirmText,
    String negativeText = defaultCancelText,
    bool isPositiveDestructive = false,
    bool swapButtonPositions = false,
    bool isMandatory = false,
    IconData? icon,
    EdgeInsets? customInsetPadding,
  }) async {
    final ctx = _resolveContext(context);

    final result = await showDialog<bool?>(
      context: ctx,
      barrierDismissible: !isMandatory,
      builder: (dialogContext) {
        final negativeButton = TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            negativeText,
            style: TextStyle(
              color: Theme.of(
                dialogContext,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              fontWeight: FontWeight.w600,
            ),
          ),
        );

        final positiveButton = ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isPositiveDestructive
                ? AppColors.error
                : AppColors.primary,
            foregroundColor: Colors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: buttonBorderRadius,
            ),
            elevation: 0,
          ),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            positiveText,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );

        final actions = swapButtonPositions
            ? [positiveButton, negativeButton]
            : [negativeButton, positiveButton];

        return PopScope(
          canPop: !isMandatory,
          child: AlertDialog(
            shape: const RoundedRectangleBorder(borderRadius: borderRadius),
            insetPadding: customInsetPadding ?? insetPadding,
            title: Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    color: isPositiveDestructive
                        ? AppColors.error
                        : AppColors.primary,
                    size: iconSize,
                  ),
                  const SizedBox(width: iconSpacing),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: titleFontSize,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            content: Text(
              message,
              style: TextStyle(
                fontSize: messageFontSize,
                color: Theme.of(
                  dialogContext,
                ).colorScheme.onSurface.withValues(alpha: 0.8),
                height: messageLineHeight,
              ),
            ),
            actions: actions,
          ),
        );
      },
    );

    return result;
  }

  /// Hộp thoại xác nhận hành động (VD: Hủy kết nối, Xóa dữ liệu).
  ///
  /// Giữ tương thích ngược với các caller hiện có, ủy quyền xử lý cho [showTwoOptionsDialog].
  static Future<bool> showConfirmDialog(
    BuildContext context, {
    required String title,
    required String message,
    String confirmText = defaultConfirmText,
    String cancelText = defaultCancelText,
    bool isDestructive = false,
    IconData? icon,
    EdgeInsets? customInsetPadding,
  }) async {
    final result = await showTwoOptionsDialog(
      context: context,
      title: title,
      message: message,
      positiveText: confirmText,
      negativeText: cancelText,
      isPositiveDestructive: isDestructive,
      icon: icon,
      customInsetPadding: customInsetPadding,
    );
    return result ?? false;
  }
}
