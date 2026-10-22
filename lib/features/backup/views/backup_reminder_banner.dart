import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../device/bloc/device_profile_cubit.dart';
import '../../device/bloc/device_setup_bloc.dart';
import '../../device/device_profile_page.dart';
import '../bloc/backup_reminder_cubit.dart';

/// Banner nhắc sao lưu trên tab Kênh (BACKLOG 1.9). "Sao lưu ngay" mở trang
/// thiết bị (mục sao lưu nằm ở đó); quay về thì đánh giá lại.
class BackupReminderBanner extends StatelessWidget {
  const BackupReminderBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final visible = context.watch<BackupReminderCubit>().state;
    if (!visible) return const SizedBox.shrink();

    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    return MaterialBanner(
      backgroundColor: scheme.tertiaryContainer,
      leading: Icon(Icons.shield_outlined, color: scheme.onTertiaryContainer),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.backupReminderTitle,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(color: scheme.onTertiaryContainer),
          ),
          const SizedBox(height: 2),
          Text(l10n.backupReminderMessage, style: TextStyle(color: scheme.onTertiaryContainer)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => context.read<BackupReminderCubit>().snooze(),
          child: Text(l10n.backupReminderLater),
        ),
        FilledButton.tonal(
          onPressed: () => _openBackup(context),
          child: Text(l10n.backupReminderAction),
        ),
      ],
    );
  }

  Future<void> _openBackup(BuildContext context) async {
    final reminder = context.read<BackupReminderCubit>();
    final setupBloc = context.read<DeviceSetupBloc>();
    final profileCubit = context.read<DeviceProfileCubit>();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: setupBloc),
            BlocProvider.value(value: profileCubit),
          ],
          child: const DeviceProfilePage(),
        ),
      ),
    );
    reminder.recheck();
  }
}
