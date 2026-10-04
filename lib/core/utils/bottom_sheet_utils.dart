import 'package:flutter/material.dart';

import 'dialog_utils.dart';

/// Tiện ích hiển thị Modal BottomSheet chuẩn hóa cho toàn bộ dự án
class BottomSheetUtils {
  BottomSheetUtils._();

  // ==========================================
  // HẰNG SỐ GIAO DIỆN CHUẨN (UI TOKENS)
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

  /// Helper lấy BuildContext an toàn từ tham số hoặc [DialogUtils.navigatorKey]
  static BuildContext _resolveContext(BuildContext? context) {
    final ctx = context ?? DialogUtils.navigatorKey.currentContext;
    if (ctx == null) {
      throw StateError(
        'Không tìm thấy BuildContext để hiển thị BottomSheet. Hãy truyền context hoặc cài đặt navigatorKey trong MaterialApp.',
      );
    }
    return ctx;
  }

  /// Hiển thị container Modal BottomSheet chuẩn dự án cho nội dung tùy biến (custom content).
  ///
  /// [child]: Widget nội dung bên trong BottomSheet (tham số bắt buộc).
  /// Cung cấp sẵn khung chuẩn: bo góc trên 20dp, drag handle ở đỉnh,
  /// padding bàn phím [viewInsets.bottom], màu nền chuẩn theo theme.
  static Future<T?> showBaseForm<T>({
    required Widget child,
    BuildContext? context,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
    bool showDragHandle = true,
  }) {
    final ctx = _resolveContext(context);

    return showModalBottomSheet<T>(
      context: ctx,
      isScrollControlled: true,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color:
              backgroundColor ?? Theme.of(sheetContext).scaffoldBackgroundColor,
          borderRadius: borderRadius,
          boxShadow: defaultBoxShadow,
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showDragHandle)
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
                        onPressed: () => Navigator.of(sheetContext).pop(),
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

  static Future<T?> showAppBottomSheet<T>({
    required Widget child,
    BuildContext? context,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
    Color? backgroundColor,
    bool showDragHandle = true,
  }) {
    return showBaseForm<T>(
      child: child,
      context: context,
      title: title,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: backgroundColor,
      showDragHandle: showDragHandle,
    );
  }
}
