import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/models/channel_member_model.dart';
import '../../../core/utils/dialog_utils.dart';
import '../bloc/channel_detail_bloc.dart';

/// Danh sách thành viên hiện tại trong kênh.
class MembersView extends StatelessWidget {
  const MembersView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ChannelDetailBloc, ChannelDetailState, List<ChannelMemberModel>>(
      selector: (state) => state.members,
      builder: (context, members) {
        final l10n = context.l10n;
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.channelDetailMembersTitle(members.length),
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: members.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return ListTile(
                      dense: true,
                      visualDensity: const VisualDensity(vertical: -4),
                      minVerticalPadding: 0,
                      minTileHeight: 0,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        member.isActive ? Icons.smartphone_rounded : Icons.block,
                        color: member.isActive ? null : colorScheme.error,
                      ),
                      title: Text(
                        member.deviceName,
                        style: TextStyle(
                          decoration: member.isActive
                              ? null
                              : TextDecoration.lineThrough,
                        ),
                      ),
                      subtitle: Text(
                        member.isActive
                            ? l10n.channelDetailMemberJoinedEpoch(member.joinedEpoch)
                            : l10n.channelDetailMemberRevokedStatus,
                      ),
                      trailing: member.isActive
                          ? IconButton(
                              tooltip: l10n.channelDetailRevokeTooltip,
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                Icons.person_remove_rounded,
                                color: colorScheme.error,
                              ),
                              onPressed: () => _revoke(context, member),
                            )
                          : null,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
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
        BlocProvider.of<ChannelDetailBloc>(context)
            .add(ChannelDetailMemberRevoked(member.deviceId));
      }
    });
  }
}
