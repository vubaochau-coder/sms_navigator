import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../bloc/channel_bloc.dart';
import 'channel_card_view.dart';
import 'pending_join_request_card.dart';

export 'pending_join_request_card.dart';

/// Danh sách các kênh do người dùng làm Chủ kênh (Owner).
class OwnedChannelListView extends StatelessWidget {
  const OwnedChannelListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChannelBloc, ChannelState>(
      buildWhen: (prev, current) =>
          prev.isLoading != current.isLoading ||
          prev.ownedChannels != current.ownedChannels,
      builder: (context, state) {
        if (state.isLoading && state.ownedChannels.isEmpty) {
          return const ShimmerLoadingList(
            itemCount: 5,
            padding: EdgeInsets.fromLTRB(12, 8, 12, 96),
            cardHeight: 76,
          );
        }

        if (state.ownedChannels.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<ChannelBloc>().add(const ChannelLoadDataEvent());
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ChannelEmptyPane(
                    message: context.l10n.channelOwnedEmptyMessage,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            context.read<ChannelBloc>().add(const ChannelLoadDataEvent());
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
            itemCount: state.ownedChannels.length,
            itemBuilder: (context, index) =>
                ChannelCardView(channel: state.ownedChannels[index]),
          ),
        );
      },
    );
  }
}

/// Danh sách các kênh mà người dùng là Thành viên (Member).
class JoinedChannelListView extends StatelessWidget {
  const JoinedChannelListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChannelBloc, ChannelState>(
      buildWhen: (prev, current) =>
          prev.isLoading != current.isLoading ||
          prev.joinedChannels != current.joinedChannels ||
          prev.pendingJoinRequests != current.pendingJoinRequests,
      builder: (context, state) {
        if (state.isLoading &&
            state.joinedChannels.isEmpty &&
            state.pendingJoinRequests.isEmpty) {
          return const ShimmerLoadingList(
            itemCount: 5,
            padding: EdgeInsets.fromLTRB(12, 8, 12, 96),
            cardHeight: 76,
          );
        }

        if (state.joinedChannels.isEmpty && state.pendingJoinRequests.isEmpty) {
          return RefreshIndicator(
            onRefresh: () async {
              context.read<ChannelBloc>().add(const ChannelLoadDataEvent());
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ChannelEmptyPane(
                    message: context.l10n.channelJoinedEmptyMessage,
                  ),
                ),
              ],
            ),
          );
        }

        final l10n = context.l10n;
        final hasPending = state.pendingJoinRequests.isNotEmpty;
        final hasJoined = state.joinedChannels.isNotEmpty;

        return RefreshIndicator(
          onRefresh: () async {
            context.read<ChannelBloc>().add(const ChannelLoadDataEvent());
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              const SliverPadding(padding: EdgeInsets.only(top: 8)),
              if (hasPending) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                    child: Text(
                      l10n.channelPendingRequestsHeader(
                        state.pendingJoinRequests.length,
                      ),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
                SliverList.builder(
                  itemCount: state.pendingJoinRequests.length,
                  itemBuilder: (context, index) => PendingJoinRequestCard(
                    request: state.pendingJoinRequests[index],
                  ),
                ),
              ],
              if (hasJoined) ...[
                if (hasPending)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: Text(
                        l10n.channelJoinedSectionTitle,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                SliverList.builder(
                  itemCount: state.joinedChannels.length,
                  itemBuilder: (context, index) => ChannelCardView(
                    channel: state.joinedChannels[index],
                  ),
                ),
              ],
              const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
            ],
          ),
        );
      },
    );
  }
}

/// Màn hình rỗng có cùng cấu trúc với [SmsEmptyPane] ở `sms_page`.
class ChannelEmptyPane extends StatelessWidget {
  const ChannelEmptyPane({
    super.key,
    required this.message,
    this.icon = Icons.hub_outlined,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
