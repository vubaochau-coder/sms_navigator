import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/repositories/backup_repository.dart';
import '../../core/ui/toast_utils.dart';
import 'backup_messages.dart';
import 'bloc/backup_restore_cubit.dart';

/// Khôi phục từ file `.smsnav` (BACKLOG 1.1). Mở từ Splash lần đầu; trả về
/// `true` qua `Navigator.pop` khi khôi phục thành công.
class BackupRestorePage extends StatelessWidget {
  const BackupRestorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => BackupRestoreCubit(repository: ctx.read<BackupRepository>()),
      child: const _BackupRestoreView(),
    );
  }
}

class _BackupRestoreView extends StatefulWidget {
  const _BackupRestoreView();

  @override
  State<_BackupRestoreView> createState() => _BackupRestoreViewState();
}

class _BackupRestoreViewState extends State<_BackupRestoreView> {
  final _passphrase = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _passphrase.dispose();
    super.dispose();
  }

  void _restore() {
    final text = _passphrase.text;
    if (text.isEmpty) return;
    FocusScope.of(context).unfocus();
    context.read<BackupRestoreCubit>().restore(text);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return BlocConsumer<BackupRestoreCubit, BackupRestoreState>(
      listenWhen: (previous, current) => current.status != previous.status,
      listener: (context, state) {
        if (state.status == BackupRestoreStatus.success) {
          ToastUtils.showSuccess(l10n.backupRestoreSuccess(state.summary?.channelCount ?? 0));
          Navigator.of(context).pop(true);
        }
      },
      builder: (context, state) {
        final failure = state.failure;
        final error = failure == null ? null : backupFailureMessage(failure);
        final restoring = state.status == BackupRestoreStatus.restoring;

        return Scaffold(
          appBar: AppBar(title: Text(l10n.backupRestoreTitle)),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
                Icon(Icons.settings_backup_restore_rounded, size: 56, color: colorScheme.primary),
                const SizedBox(height: 16),
                Text(l10n.backupRestoreIntro, style: theme.textTheme.bodyMedium),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: colorScheme.onTertiaryContainer),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n.backupRestoreOldDeviceWarning,
                          style: TextStyle(fontSize: 12, color: colorScheme.onTertiaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: state.isBusy ? null : () => context.read<BackupRestoreCubit>().pickFile(),
                  icon: Icon(state.hasFile ? Icons.check_circle_rounded : Icons.folder_open_rounded),
                  label: Text(state.hasFile ? l10n.backupChangeFile : l10n.backupPickFile),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
                if (state.hasFile) ...[
                  const SizedBox(height: 8),
                  Text(
                    l10n.backupFileSelected,
                    style: TextStyle(fontSize: 12, color: colorScheme.primary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passphrase,
                    obscureText: _obscure,
                    enabled: !restoring,
                    enableSuggestions: false,
                    autocorrect: false,
                    onSubmitted: (_) => _restore(),
                    decoration: InputDecoration(
                      labelText: l10n.backupPassphraseLabel,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        tooltip: _obscure ? l10n.backupShowPassphrase : l10n.backupHidePassphrase,
                        icon: Icon(_obscure ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 12),
                  Text(error, style: TextStyle(color: colorScheme.error, fontSize: 13)),
                ],
                if (state.hasFile) ...[
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: restoring ? null : _restore,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: restoring
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 12),
                              Text(l10n.backupRestoring),
                            ],
                          )
                        : Text(l10n.backupRestoreAction),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
