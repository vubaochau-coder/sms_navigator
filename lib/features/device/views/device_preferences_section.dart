import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/theme_cubit.dart';
import '../../../core/utils/dialog_utils.dart';
import '../../splash/splash_page.dart';
import '../bloc/device_profile_cubit.dart';
import '../../../core/l10n/app_l10n.dart';
import '../../../core/extensions/context_extensions.dart';

/// Section cài đặt & tùy chọn: Chế độ hiển thị (Theme) và Xóa dữ liệu thiết bị.
class DevicePreferencesSection extends StatelessWidget {
  const DevicePreferencesSection({super.key});

  Future<void> _handleClearDeviceData(BuildContext context) async {
    final confirmed = await DialogUtils.showTwoOptionsDialog(
      context: context,
      title: AppL10n.current.deviceResetDialogTitle,
      message: AppL10n.current.deviceResetDialogMessage,
      positiveText: AppL10n.current.deviceResetConfirm,
      negativeText: AppL10n.current.cancel,
      isPositiveDestructive: true,
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    final cubit = context.read<DeviceProfileCubit>();
    final success = await cubit.clearDeviceData();
    if (!success) return;

    if (!context.mounted) return;
    Navigator.of(context).pop();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(
        builder: (_) => const SplashPage(autoStart: true),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentTheme = context.watch<ThemeCubit>().state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            context.l10n.devicePreferencesTitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
          ),
          color: colorScheme.surface,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.palette_outlined,
                          size: 18,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          context.l10n.themeModeLabel,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<ThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text(context.l10n.themeSystem, style: const TextStyle(fontSize: 12)),
                          icon: const Icon(Icons.brightness_auto_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text(context.l10n.themeLight, style: const TextStyle(fontSize: 12)),
                          icon: const Icon(Icons.light_mode_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text(context.l10n.themeDark, style: const TextStyle(fontSize: 12)),
                          icon: const Icon(Icons.dark_mode_rounded, size: 16),
                        ),
                      ],
                      selected: {currentTheme},
                      onSelectionChanged: (selected) {
                        context.read<ThemeCubit>().setThemeMode(selected.first);
                      },
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                leading: Icon(
                  Icons.delete_sweep_outlined,
                  color: colorScheme.error,
                ),
                title: Text(
                  context.l10n.deviceResetTitle,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.error,
                  ),
                ),
                subtitle: Text(
                  context.l10n.deviceResetSubtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.error,
                ),
                onTap: () => _handleClearDeviceData(context),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
