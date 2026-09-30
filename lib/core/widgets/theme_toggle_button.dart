import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../extensions/context_extensions.dart';
import '../theme/theme_cubit.dart';

/// Nút chuyển đổi nhanh chế độ sáng/tối dùng chung toàn ứng dụng.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        final isDark = themeMode == ThemeMode.dark ||
            (themeMode == ThemeMode.system &&
                MediaQuery.of(context).platformBrightness == Brightness.dark);

        return IconButton(
          tooltip: isDark
              ? l10n.themeSwitchToLight
              : l10n.themeSwitchToDark,
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
