import 'package:flutter/material.dart';

/// Tiện ích hiển thị Modal BottomSheet chuẩn hóa
class BottomSheetUtils {
  BottomSheetUtils._();

  // ==========================================
  // HẰNG SỐ GIAO DIỆN CHUẨN (UI TOKENS)
  // Các màn hình hoặc component custom có thể dùng làm chuẩn
  // ==========================================
  static const double topRadius = 20.0;
  static const BorderRadius borderRadius = BorderRadius.vertical(
    top: Radius.circular(topRadius),
  );

  static const double dragHandleWidth = 36.0;
  static const double dragHandleHeight = 4.0;
  static const double dragHandleRadius = 2.0;
  static const EdgeInsets dragHandleMargin = EdgeInsets.only(
    top: 10,
    bottom: 4,
  );

  static const EdgeInsets headerPadding = EdgeInsets.fromLTRB(16, 12, 16, 8);
  static const double titleFontSize = 16.0;
  static const double closeIconSize = 20.0;

  static const List<BoxShadow> defaultBoxShadow = [
    BoxShadow(color: Color(0x26000000), blurRadius: 16, offset: Offset(0, -4)),
  ];

  /// Modal Bottom Sheet chuẩn hóa dạng Soft Modern
  static Future<T?> showAppBottomSheet<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: borderRadius,
          boxShadow: defaultBoxShadow,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  margin: dragHandleMargin,
                  width: dragHandleWidth,
                  height: dragHandleHeight,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(dragHandleRadius),
                  ),
                ),
              ),
              if (title != null) ...[
                Padding(
                  padding: headerPadding,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: closeIconSize,
                        ),
                        onPressed: () => Navigator.of(ctx).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
              ],
              Flexible(child: child),
            ],
          ),
        ),
      ),
    );
  }
}
