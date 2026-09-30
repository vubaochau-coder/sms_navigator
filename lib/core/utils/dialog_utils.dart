import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Tiện ích hiển thị Dialog / Alert thống nhất
class DialogUtils {
  DialogUtils._();

  // ==========================================
  // HẰNG SỐ GIAO DIỆN CHUẨN (UI TOKENS)
  // Các màn hình hoặc component custom có thể dùng làm chuẩn
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

  static const EdgeInsets insetPadding = EdgeInsets.symmetric(
    horizontal: 24,
    vertical: 24,
  );
  static const String defaultConfirmText = 'Xác nhận';
  static const String defaultCancelText = 'Hủy bỏ';

  /// Hộp thoại xác nhận hành động (VD: Hủy kết nối, Xóa dữ liệu)
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
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: borderRadius),
        insetPadding: customInsetPadding ?? insetPadding,
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isDestructive ? AppColors.error : AppColors.primary,
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
            color: Theme.of(ctx).colorScheme.onSurface.withValues(alpha: 0.8),
            height: messageLineHeight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              cancelText,
              style: TextStyle(
                color: Theme.of(
                  ctx,
                ).colorScheme.onSurface.withValues(alpha: 0.6),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDestructive
                  ? AppColors.error
                  : AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: buttonBorderRadius),
              elevation: 0,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              confirmText,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
