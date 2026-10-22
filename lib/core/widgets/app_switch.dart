import 'package:flutter/material.dart';

/// Switch dùng chung toàn ứng dụng với màu đồng nhất. Trạng thái disabled
/// vẫn hiển thị rõ ràng thay vì bị mờ theo mặc định của Material 3.
/// Mặc định thu nhỏ kích thước [scale = 0.8] (~42x26 dp) để giao diện gọn gàng hơn
/// so với kích thước gốc 52x32 dp của Material 3.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.scale = 0.8,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  /// Tỉ lệ thu phóng switch (mặc định 0.8 ~ 42x26 dp).
  final double scale;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = onChanged != null;

    final switchWidget = Switch(
      value: value,
      onChanged: onChanged,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (value) {
          return isEnabled
              ? colorScheme.primary
              : colorScheme.primary.withValues(alpha: 0.4);
        }
        return isEnabled
            ? colorScheme.surfaceContainerHighest
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5);
      }),
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (value) return colorScheme.onPrimary;
        return isEnabled ? colorScheme.onSurfaceVariant : colorScheme.outline;
      }),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    );

    if (scale == 1.0) {
      return switchWidget;
    }

    return SizedBox(
      width: 52 * scale,
      height: 32 * scale,
      child: FittedBox(
        fit: BoxFit.contain,
        child: switchWidget,
      ),
    );
  }
}
