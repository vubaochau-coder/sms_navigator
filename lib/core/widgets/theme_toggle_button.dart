import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../theme/theme_cubit.dart';

/// Nút chuyển đổi nhanh chế độ sáng/tối dùng chung toàn ứng dụng.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({
    super.key,
    this.iconSize,
    this.padding,
    this.tooltipDark = 'Chuyển sang nền sáng',
    this.tooltipLight = 'Chuyển sang nền tối',
  });

  final double? iconSize;
  final EdgeInsetsGeometry? padding;
  final String tooltipDark;
  final String tooltipLight;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        final isDark = themeMode == ThemeMode.dark ||
            (themeMode == ThemeMode.system &&
                MediaQuery.of(context).platformBrightness == Brightness.dark);

        return IconButton(
          iconSize: iconSize,
          padding: padding,
          tooltip: isDark ? tooltipDark : tooltipLight,
          icon: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              key: ValueKey<bool>(isDark),
            ),
          ),
          onPressed: () => context.read<ThemeCubit>().toggleTheme(),
        );
      },
    );
  }
}
