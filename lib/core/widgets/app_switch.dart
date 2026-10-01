import 'package:flutter/material.dart';

/// Switch dùng chung toàn ứng dụng với màu đồng nhất. Trạng thái disabled
/// vẫn hiển thị rõ ràng thay vì bị mờ theo mặc định của Material 3.
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    super.key,
    required this.value,
    this.onChanged,
  });

  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = onChanged != null;

    return Switch(
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
  }
}
