import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../bloc/channel_bloc.dart';
import 'channel_card_view.dart';
import 'channel_section_header_view.dart';

/// View hiển thị danh sách kênh gồm 2 nhóm (Owned & Joined) và trạng thái rỗng.
class ChannelListView extends StatelessWidget {
  const ChannelListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChannelBloc, ChannelState>(
      builder: (context, state) {
        if (state.isLoading && state.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        final l10n = context.l10n;

        return RefreshIndicator(
          onRefresh: () async {
            context.read<ChannelBloc>().add(const ChannelLoadDataEvent());
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              if (state.isEmpty)
                const ChannelEmptyPane()
              else ...[
                ChannelSectionHeaderView(
                  title: l10n.channelOwnedSectionTitle,
                  count: state.ownedChannels.length,
                ),
                for (final channel in state.ownedChannels)
                  ChannelCardView(channel: channel),
                ChannelSectionHeaderView(
                  title: l10n.channelJoinedSectionTitle,
                  count: state.joinedChannels.length,
                ),
                for (final channel in state.joinedChannels)
                  ChannelCardView(channel: channel),
              ],
            ],
          ),
        );
      },
    );
  }
}

class ChannelEmptyPane extends StatelessWidget {
  const ChannelEmptyPane({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 120),
      child: Center(
        child: Text(
          context.l10n.channelEmptyMessage,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
