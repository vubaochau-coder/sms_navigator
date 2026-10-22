import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../backup/backup_restore_page.dart';
import '../bloc/splash_bloc.dart';
import '../bloc/splash_event.dart';

/// Lựa chọn ở lần mở đầu tiên: tạo danh tính mới hay khôi phục `.smsnav` (BACKLOG 1.1).
class SplashSetupChoiceView extends StatelessWidget {
  final VoidCallback? onNewDevice;
  final VoidCallback? onRestore;

  const SplashSetupChoiceView({
    super.key,
    this.onNewDevice,
    this.onRestore,
  });

  Future<void> _restore(BuildContext context) async {
    if (onRestore != null) {
      onRestore!();
      return;
    }
    final bloc = context.read<SplashBloc>();
    final defaultName = context.l10n.splashDefaultDeviceName;
    final restored = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const BackupRestorePage()),
    );
    // Đã có device token từ bản sao lưu → chạy lại bootstrap (nhánh xác thực).
    if (restored == true) {
      bloc.add(SplashRetried(defaultDeviceName: defaultName));
    }
  }

  void _newDevice(BuildContext context) {
    if (onNewDevice != null) {
      onNewDevice!();
      return;
    }
    context.read<SplashBloc>().add(
      SplashNewDeviceChosen(
        defaultDeviceName: context.l10n.splashDefaultDeviceName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.splashSetupChoiceTitle,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        SplashChoiceButton(
          icon: Icons.add_moderator_rounded,
          title: l10n.splashSetupNewDevice,
          subtitle: l10n.splashSetupNewDeviceSubtitle,
          primary: true,
          onPressed: () => _newDevice(context),
        ),
        const SizedBox(height: 12),
        SplashChoiceButton(
          icon: Icons.settings_backup_restore_rounded,
          title: l10n.splashSetupRestore,
          subtitle: l10n.splashSetupRestoreSubtitle,
          onPressed: () => _restore(context),
        ),
      ],
    );
  }
}

/// Nút bấm tuỳ chọn cho màn thiết lập ban đầu (tạo mới hoặc khôi phục sao lưu).
class SplashChoiceButton extends StatelessWidget {
  const SplashChoiceButton({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final foreground = primary ? colorScheme.onPrimary : colorScheme.primary;
    final child = Row(
      children: [
        Icon(icon, color: foreground),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: foreground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: foreground.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ],
    );
    const padding = EdgeInsets.symmetric(horizontal: 16);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    return primary
        ? FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              padding: padding,
              shape: shape,
            ),
            child: child,
          )
        : OutlinedButton(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              padding: padding,
              shape: shape,
            ),
            child: child,
          );
  }
}
