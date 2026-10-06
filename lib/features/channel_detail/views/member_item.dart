import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/models/channel_member_model.dart';
import '../../../core/utils/dialog_utils.dart';
import '../bloc/channel_detail_bloc.dart';

/// Widget hiển thị thông tin và hành động của một thành viên kênh.
class MemberItem extends StatelessWidget {
  const MemberItem({
    super.key,
    required this.member,
    this.isOwner = false,
  });

  final ChannelMemberModel member;
  final bool isOwner;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Icon(
          member.isActive ? Icons.smartphone_rounded : Icons.block,
          color: member.isActive ? null : colorScheme.error,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                member.deviceName,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  decoration: member.isActive
                      ? null
                      : TextDecoration.lineThrough,
                  color: member.isActive ? null : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                member.isActive
                    ? l10n.channelDetailMemberJoinedEpoch(member.joinedEpoch)
                    : l10n.channelDetailMemberRevokedStatus,
                style: textTheme.bodySmall?.copyWith(
                  color: member.isActive
                      ? colorScheme.onSurfaceVariant
                      : colorScheme.error,
                ),
              ),
            ],
          ),
        ),
        if (isOwner)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  size: 12,
                  color: colorScheme.onSecondaryContainer,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.channelDetailMemberOwner,
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        // Owner không thể tự thu hồi chính mình (server từ chối — API spec §4.6)
        if (member.isActive && !isOwner)
          IconButton(
            tooltip: l10n.channelDetailRevokeTooltip,
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            visualDensity: VisualDensity.compact,
            icon: Icon(Icons.person_remove_rounded, color: colorScheme.error),
            onPressed: () => _revoke(context, member),
          ),
      ],
    );
  }

  void _revoke(BuildContext context, ChannelMemberModel member) {
    final l10n = context.l10n;
    DialogUtils.showConfirmDialog(
      context: context,
      title: l10n.channelDetailRevokeDialogTitle,
      message: l10n.channelDetailRevokeDialogMessage(member.deviceName),
      confirmText: l10n.channelDetailRevokeConfirm,
      isDestructive: true,
    ).then((confirmed) {
      if (confirmed && context.mounted) {
        BlocProvider.of<ChannelDetailBloc>(
          context,
        ).add(ChannelDetailMemberRevoked(member.deviceId));
      }
    });
  }
}
