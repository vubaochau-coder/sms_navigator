import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/ui/dialog_utils.dart';
import '../bloc/channel_detail_bloc.dart';

enum _ChannelMenuAction { rename }

/// Menu "⋮" trên AppBar chi tiết kênh: các thao tác quản lý kênh.
class ChannelDetailMenuButton extends StatelessWidget {
  const ChannelDetailMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isOwner = context.select<ChannelDetailBloc, bool>((bloc) => bloc.state.isOwner);
    final isBusy = context.select<ChannelDetailBloc, bool>(
      (bloc) => bloc.state.isMutating || bloc.state.detail == null,
    );
    if (!isOwner) return const SizedBox.shrink();

    return PopupMenuButton<_ChannelMenuAction>(
      tooltip: l10n.channelDetailMoreTooltip,
      enabled: !isBusy,
      onSelected: (action) => switch (action) {
        _ChannelMenuAction.rename => _rename(context),
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _ChannelMenuAction.rename,
          child: ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: Text(l10n.channelRenameAction),
            contentPadding: EdgeInsets.zero,
          ),
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
}
