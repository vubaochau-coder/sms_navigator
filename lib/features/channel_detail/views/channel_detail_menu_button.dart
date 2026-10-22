import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/ui/dialog_utils.dart';
import '../bloc/channel_detail_bloc.dart';

enum _ChannelMenuAction { rename, archive, leave }

/// Menu "⋮" trên AppBar chi tiết kênh: Owner (đổi tên, giải tán), Member (rời kênh).
class ChannelDetailMenuButton extends StatelessWidget {
  const ChannelDetailMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasDetail = context.select<ChannelDetailBloc, bool>((bloc) => bloc.state.detail != null);
    final isOwner = context.select<ChannelDetailBloc, bool>((bloc) => bloc.state.isOwner);
    final isBusy = context.select<ChannelDetailBloc, bool>((bloc) => bloc.state.isMutating);
    if (!hasDetail) return const SizedBox.shrink();

    final actions = isOwner
        ? const [_ChannelMenuAction.rename, _ChannelMenuAction.archive]
        : const [_ChannelMenuAction.leave];

    return PopupMenuButton<_ChannelMenuAction>(
      tooltip: l10n.channelDetailMoreTooltip,
      enabled: !isBusy,
      onSelected: (action) => switch (action) {
        _ChannelMenuAction.rename => _rename(context),
        _ChannelMenuAction.archive => _archive(context),
        _ChannelMenuAction.leave => _leave(context),
      },
      itemBuilder: (context) => [
        for (final action in actions)
          PopupMenuItem(
            value: action,
            child: _MenuRow(action: action),
          ),
      ],
    );
  }

  Future<void> _rename(BuildContext context) async {
    final l10n = context.l10n;
    final bloc = context.read<ChannelDetailBloc>();
    final name = await DialogUtils.showInputDialog(
      context: context,
      title: l10n.channelRenameAction,
      labelText: l10n.channelNameLabel,
      hintText: l10n.channelNameHint,
      initialValue: bloc.state.detail?.name,
      maxLength: 100,
      icon: Icons.edit_outlined,
      confirmText: l10n.channelRenameConfirm,
      cancelText: l10n.cancel,
    );
    if (name != null && name.trim().isNotEmpty) {
      bloc.add(ChannelDetailRenamed(name));
    }
  }

  Future<void> _archive(BuildContext context) async {
    final l10n = context.l10n;
    final bloc = context.read<ChannelDetailBloc>();
    final confirmed = await DialogUtils.showConfirmDialog(
      context: context,
      title: l10n.channelArchiveConfirmTitle,
      message: l10n.channelArchiveConfirmMessage(bloc.state.detail?.name ?? ''),
      confirmText: l10n.channelArchiveAction,
      cancelText: l10n.cancel,
      isDestructive: true,
      icon: Icons.delete_forever_outlined,
    );
    if (confirmed) bloc.add(const ChannelDetailArchived());
  }

  Future<void> _leave(BuildContext context) async {
    final l10n = context.l10n;
    final bloc = context.read<ChannelDetailBloc>();
    final confirmed = await DialogUtils.showConfirmDialog(
      context: context,
      title: l10n.channelLeaveConfirmTitle,
      message: l10n.channelLeaveConfirmMessage(bloc.state.detail?.name ?? ''),
      confirmText: l10n.channelLeaveAction,
      cancelText: l10n.cancel,
      isDestructive: true,
      icon: Icons.logout_rounded,
    );
    if (confirmed) bloc.add(const ChannelDetailLeft());
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.action});

  final _ChannelMenuAction action;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final danger = Theme.of(context).colorScheme.error;
    final (icon, label, color) = switch (action) {
      _ChannelMenuAction.rename => (Icons.edit_outlined, l10n.channelRenameAction, null),
      _ChannelMenuAction.archive => (Icons.delete_forever_outlined, l10n.channelArchiveAction, danger),
      _ChannelMenuAction.leave => (Icons.logout_rounded, l10n.channelLeaveAction, danger),
    };
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(label, style: color == null ? null : TextStyle(color: color)),
      contentPadding: EdgeInsets.zero,
    );
  }
}
