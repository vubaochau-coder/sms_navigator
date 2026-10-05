import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Thành viên (${members.length})',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                for (final member in members)
                  ListTile(
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
                          ? 'Tham gia epoch ${member.joinedEpoch}'
                          : 'Đã thu hồi',
                    ),
                    trailing: member.isActive
                        ? IconButton(
                            tooltip: 'Thu hồi',
                            icon: Icon(
                              Icons.person_remove_rounded,
                              color: colorScheme.error,
                            ),
                            onPressed: () => _revoke(context, member),
                          )
                        : null,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _revoke(BuildContext context, ChannelMemberModel member) {
    DialogUtils.showConfirmDialog(
      context: context,
      title: 'Thu hồi thành viên?',
      message:
          'Thu hồi "${member.deviceName}" là hành động vĩnh viễn. Khóa kênh sẽ được xoay ngay để member này không đọc được tin mới.',
      confirmText: 'Thu hồi',
      isDestructive: true,
    ).then((confirmed) {
      if (confirmed && context.mounted) {
        BlocProvider.of<ChannelDetailBloc>(context)
            .add(ChannelDetailMemberRevoked(member.deviceId));
      }
    });
  }
}
