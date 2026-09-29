import 'package:flutter/widgets.dart';

/// Hằng số kích thước & padding chuẩn hóa cho ứng dụng SMS Navigator.
class Dimens {
  Dimens._();

  /// Padding ngang chuẩn cho toàn bộ màn hình: 8px
  static const double screenPaddingHorizontal = 8.0;

  /// Padding dọc chuẩn cho phạm vi màn hình: 12px
  static const double screenPaddingVertical = 12.0;

  /// Padding thống nhất cho phạm vi màn hình: horizontal 8px, vertical 12px
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenPaddingHorizontal,
    vertical: screenPaddingVertical,
  );
}
