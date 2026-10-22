import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/repositories/backup_repository.dart';
import '../bloc/backup_export_cubit.dart';
import 'backup_passphrase_dialog.dart';

/// Section "Sao lưu & khôi phục" trong hồ sơ thiết bị (BACKLOG 1.1).
/// Khôi phục chỉ có ở Splash lần đầu — trên máy đang chạy, ghi đè danh tính
/// sẽ làm mất kênh hiện tại.
class DeviceBackupSection extends StatelessWidget {
  const DeviceBackupSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => BackupExportCubit(repository: ctx.read<BackupRepository>()),
      child: const _DeviceBackupView(),
    );
  }
}

class _DeviceBackupView extends StatelessWidget {
  const _DeviceBackupView();

  Future<void> _export(BuildContext context) async {
    final cubit = context.read<BackupExportCubit>();
    final passphrase = await showBackupPassphraseDialog(context);
    if (passphrase == null) return;
    await cubit.export(passphrase);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final isExporting = context.select((BackupExportCubit c) => c.state.isExporting);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            l10n.backupSectionTitle,
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
            side: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.4)),
          ),
          color: colorScheme.surface,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            leading: Icon(Icons.backup_outlined, color: colorScheme.primary),
            title: Text(
              l10n.backupExportTitle,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              l10n.backupExportSubtitle,
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            enabled: !isExporting,
            onTap: () => _export(context),
          ),
        ),
      ],
    );
  }
}
