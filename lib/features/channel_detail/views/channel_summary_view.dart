import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/models/channel_detail_model.dart';
import '../bloc/channel_detail_bloc.dart';

/// Card tóm tắt thông tin kênh: tên, Owner, số thành viên, epoch hiện tại.
class ChannelSummaryView extends StatelessWidget {
  const ChannelSummaryView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ChannelDetailBloc, ChannelDetailState, ChannelDetailModel?>(
      selector: (state) => state.detail,
      builder: (context, detail) {
        if (detail == null) return const SizedBox.shrink();

        final l10n = context.l10n;
        final textTheme = Theme.of(context).textTheme;

        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  detail.name,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Text(l10n.channelDetailOwnerServer(detail.ownerDeviceName)),
                const SizedBox(height: 4),
                Text(l10n.channelDetailMemberCount(detail.memberCount)),
                const SizedBox(height: 4),
                Text(l10n.channelDetailCurrentEpoch(detail.currentEpoch)),
              ],
            ),
          ),
        );
      },
    );
  }
}
