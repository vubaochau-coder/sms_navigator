import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/repositories/channel_repository.dart';
import 'bloc/channel_detail_bloc.dart';
import 'views/channel_detail_shimmer_view.dart';
import 'views/channel_summary_view.dart';
import 'views/invite_bottom_sheet.dart';
import 'views/members_view.dart';
import 'views/pending_requests_view.dart';

export 'views/channel_detail_shimmer_view.dart';
export 'views/channel_summary_view.dart';
export 'views/invite_bottom_sheet.dart';
export 'views/members_view.dart';
export 'views/pending_requests_view.dart';

/// Chi tiết kênh của bạn (Owner) — MOBILE_FEATURES 2.3 + 4.1–4.4:
/// tên kênh, số thành viên + danh sách thành viên, hàng đợi duyệt,
/// QR invitation deeplink v4 (countdown 10', tạo lại, hint bảo mật).
class ChannelDetailPage extends StatelessWidget {
  const ChannelDetailPage({super.key, required this.channelId});

  final String channelId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ChannelDetailBloc(
        repository: context.read<ChannelRepository>(),
        channelId: channelId,
      )..add(ChannelDetailLoaded(channelId)),
      child: const _ChannelDetailPageView(),
    );
  }
}

class _ChannelDetailPageView extends StatelessWidget {
  const _ChannelDetailPageView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(
        title: BlocSelector<ChannelDetailBloc, ChannelDetailState, String?>(
          selector: (state) => state.detail?.name,
          builder: (context, name) => Text(name ?? l10n.channelDetailTitle),
        ),
        actions: [
          BlocSelector<ChannelDetailBloc, ChannelDetailState, bool>(
            selector: (state) => state.isOwner,
            builder: (context, isOwner) {
              if (!isOwner) return const SizedBox.shrink();
              return IconButton(
                icon: const Icon(Icons.add),
                tooltip: l10n.channelDetailInviteTooltip,
                onPressed: () => InviteBottomSheet.show(context),
              );
            },
          ),
        ],
      ),
      body: BlocSelector<ChannelDetailBloc, ChannelDetailState, bool>(
        selector: (state) => state.isLoading && state.detail == null,
        builder: (context, isInitialLoading) {
          if (isInitialLoading) {
            return const ChannelDetailShimmerView();
          }

          final channelId = context.select<ChannelDetailBloc, String>(
            (bloc) => bloc.state.channelId,
          );

          return RefreshIndicator(
            onRefresh: () async {
              BlocProvider.of<ChannelDetailBloc>(
                context,
              ).add(ChannelDetailLoaded(channelId));
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              children: const [
                ChannelSummaryView(),
                SizedBox(height: 12),
                PendingRequestsView(),
                MembersView(),
              ],
            ),
          );
        },
      ),
    );
  }
}
