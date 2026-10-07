import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/utils/bottom_sheet_utils.dart';
import '../../core/widgets/app_common_widgets.dart';
import '../../core/models/whitelist_config_model.dart';
import '../../core/repositories/whitelist_repository.dart';
import 'bloc/whitelist_bloc.dart';
import 'bloc/whitelist_event.dart';
import 'bloc/whitelist_state.dart';
import 'views/whitelist_add_entry_dialog.dart';

/// Màn cấu hình Danh sách trắng SMS (deny-by-default).
class WhitelistSettingsPage extends StatelessWidget {
  const WhitelistSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => WhitelistBloc(
        repository: ctx.read<WhitelistRepository>(),
      )..add(const WhitelistStarted()),
      child: const _WhitelistSettingsView(),
    );
  }
}

class _WhitelistSettingsView extends StatelessWidget {
  const _WhitelistSettingsView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.whitelistSettingsTitle),
        actions: [
          IconButton(
            tooltip: 'Nhật ký tiếp nhận SMS',
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: () => _openRelayLogSheet(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'whitelist_settings_add_fab',
        onPressed: () {
          showDialog<void>(
            context: context,
            builder: (_) => BlocProvider.value(
              value: BlocProvider.of<WhitelistBloc>(context),
              child: const WhitelistAddEntryDialog(),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.addWhitelistDialogTitle),
      ),
      body: BlocBuilder<WhitelistBloc, WhitelistState>(
        builder: (context, state) {
          if (state.isLoading && state.config.entries.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (state.blocksEverything) const _BlockedBanner(),
              const _AllAddressesTile(),
              const _SectionCaption(),
              const Expanded(child: _EntriesSection()),
            ],
          );
        },
      ),
    );
  }

  void _openRelayLogSheet(BuildContext context) {
    BlocProvider.of<WhitelistBloc>(context).add(const WhitelistLogsRefreshed());
    BottomSheetUtils.showAppBottomSheet<void>(
      context: context,
      title: 'Nhật ký tiếp nhận SMS',
      child: const _RelayLogSheet(),
    );
  }
}

/// Sheet hiển thị nhật ký tiếp nhận SMS từ native — truy vết pipeline
/// (gate nào chặn SMS, vì sao không relay được).
class _RelayLogSheet extends StatelessWidget {
  const _RelayLogSheet();

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return BlocBuilder<WhitelistBloc, WhitelistState>(
      builder: (context, state) {
        final logs = state.recentLogs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mỗi SMS tới sẽ được ghi lại tại đây kèm lý do bị chặn '
                      '(nếu không relay được).',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Làm mới',
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () => BlocProvider.of<WhitelistBloc>(context)
                        .add(const WhitelistLogsRefreshed()),
                  ),
                ],
              ),
            ),
            if (logs.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text(
                    'Chưa có SMS nào được ghi nhận.',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: logs.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) =>
                      _RelayLogTile(log: logs[index]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RelayLogTile extends StatelessWidget {
  const _RelayLogTile({required this.log});

  final Map<String, dynamic> log;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final sender = (log['sender'] as String?) ?? '';
    final otp = (log['otp'] as String?) ?? '';
    final status = (log['status'] as String?) ?? '';
    final error = (log['error'] as String?) ?? '';
    final timestamp = log['timestamp'];

    String formattedTime = '';
    if (timestamp is int && timestamp > 0) {
      final dt = DateTime.fromMillisecondsSinceEpoch(timestamp);
      formattedTime = DateFormat('HH:mm:ss · dd/MM/yyyy').format(dt);
    }

    final (Color color, IconData icon) = switch (status) {
      'SUCCESS' => (Colors.green.shade700, Icons.check_circle_outline_rounded),
      'ENQUEUED' => (Colors.blue.shade700, Icons.schedule_send_rounded),
      'RETRYING' => (Colors.orange.shade800, Icons.refresh_rounded),
      'FAILED' => (colorScheme.error, Icons.error_outline_rounded),
      'BLOCKED' => (Colors.purple.shade700, Icons.block_rounded),
      _ => (colorScheme.onSurfaceVariant, Icons.remove_circle_outline_rounded),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        sender.isEmpty ? '(không rõ số gửi)' : sender,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
                if (formattedTime.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      formattedTime,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                if (otp.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Nội dung phát hiện: $otp',
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                if (error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      error,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BlockedBanner extends StatelessWidget {
  const _BlockedBanner();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = context.colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.tertiary),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: colorScheme.tertiary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.whitelistEmptyWarningTitle,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.whitelistEmptyWarningMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onTertiaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AllAddressesTile extends StatelessWidget {
  const _AllAddressesTile();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return BlocSelector<WhitelistBloc, WhitelistState, WhitelistMode>(
      selector: (state) => state.config.mode,
      builder: (context, mode) {
        final isAllAddresses = mode == WhitelistMode.allAddresses;
        void toggle() {
          BlocProvider.of<WhitelistBloc>(context).add(
            WhitelistModeChanged(
              isAllAddresses
                  ? WhitelistMode.explicit
                  : WhitelistMode.allAddresses,
            ),
          );
        }

        return ListTile(
          title: Text(l10n.whitelistAllAddressesToggle),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(l10n.whitelistAllAddressesDesc),
          ),
          trailing: AppSwitch(
            value: isAllAddresses,
            onChanged: (_) {
              toggle();
            },
          ),
          onTap: toggle,
        );
      },
    );
  }
}

class _SectionCaption extends StatelessWidget {
  const _SectionCaption();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = context.colorScheme;
    return BlocSelector<WhitelistBloc, WhitelistState, WhitelistMode>(
      selector: (state) => state.config.mode,
      builder: (context, mode) {
        final caption = mode == WhitelistMode.allAddresses
            ? l10n.whitelistOtpSectionCaption
            : l10n.whitelistExplicitDesc;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Text(
            caption,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        );
      },
    );
  }
}

class _EntriesSection extends StatelessWidget {
  const _EntriesSection();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = context.colorScheme;

    return BlocSelector<WhitelistBloc, WhitelistState, List<WhitelistEntryModel>>(
      selector: (state) => state.config.entries,
      builder: (context, entries) {
        if (entries.isEmpty) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 72),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.block_rounded,
                    size: 48,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.whitelistEmptyListHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: entries.length,
          itemBuilder: (context, index) {
            return _WhitelistEntryTile(entry: entries[index]);
          },
        );
      },
    );
  }
}

class _WhitelistEntryTile extends StatelessWidget {
  const _WhitelistEntryTile({required this.entry});

  final WhitelistEntryModel entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = context.colorScheme;

    return ListTile(
      leading: Icon(
        entry.allowOtp
            ? Icons.enhanced_encryption_rounded
            : Icons.sms_rounded,
        color: entry.allowOtp
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant,
      ),
      title: Text(entry.address),
      subtitle: Text(
        entry.allowOtp ? l10n.allowSendingOtp : l10n.addWhitelistHint,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          color: entry.allowOtp
              ? colorScheme.primary
              : colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: l10n.allowSendingOtp,
            child: Checkbox(
              value: entry.allowOtp,
              onChanged: (_) {
                BlocProvider.of<WhitelistBloc>(
                  context,
                ).add(WhitelistAllowOtpToggled(entry));
              },
            ),
          ),
          IconButton(
            tooltip: l10n.whitelistRemoveAction,
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () {
              BlocProvider.of<WhitelistBloc>(
                context,
              ).add(WhitelistEntryRemoved(entry));
            },
          ),
        ],
      ),
    );
  }
}
