import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/models/pairing_request_model.dart';
import '../../core/repositories/channel_repository.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/status_badge.dart';
import 'bloc/request_history_cubit.dart';

/// Owner xem lại các yêu cầu kết nối đã duyệt / từ chối / bị huỷ (BACKLOG 1.6).
class RequestHistoryPage extends StatelessWidget {
  const RequestHistoryPage({super.key, required this.channelId});

  final String channelId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RequestHistoryCubit(
        repository: context.read<ChannelRepository>(),
        channelId: channelId,
      )..load(),
      child: const RequestHistoryView(),
    );
  }
}

class RequestHistoryView extends StatelessWidget {
  const RequestHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.requestHistoryTitle)),
      body: BlocBuilder<RequestHistoryCubit, RequestHistoryState>(
        builder: (context, state) {
          final cubit = context.read<RequestHistoryCubit>();
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.hasError) {
            return EmptyStateView(
              icon: Icons.cloud_off_rounded,
              title: l10n.requestHistoryLoadFailed,
              actionLabel: l10n.requestHistoryRetry,
              onAction: cubit.load,
            );
          }
          if (state.items.isEmpty) {
            return RefreshIndicator(
              onRefresh: cubit.load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 120),
                  EmptyStateView(icon: Icons.history_rounded, title: l10n.requestHistoryEmpty),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: cubit.load,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: state.items.length + (state.hasMore ? 1 : 0),
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == state.items.length) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Center(
                      child: state.isLoadingMore
                          ? const CircularProgressIndicator()
                          : TextButton(onPressed: cubit.loadMore, child: Text(l10n.requestHistoryLoadMore)),
                    ),
                  );
                }
                return RequestHistoryTile(request: state.items[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class RequestHistoryTile extends StatelessWidget {
  const RequestHistoryTile({super.key, required this.request});

  final PairingRequestModel request;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;
    final (label, color, icon) = switch (request.status) {
      PairingRequestStatus.approved => (l10n.requestStatusApproved, Colors.green, Icons.check_circle_outline),
      PairingRequestStatus.rejected => (l10n.requestStatusRejected, scheme.error, Icons.block_outlined),
      PairingRequestStatus.cancelled => (l10n.requestStatusCancelled, scheme.outline, Icons.undo_rounded),
      PairingRequestStatus.pending => ('', scheme.outline, Icons.hourglass_empty_rounded),
    };
    final decidedAt = DateTimeUtils.tryParse(request.decidedAt ?? request.createdAt);
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(request.requesterDeviceName.isNotEmpty ? request.requesterDeviceName : '—'),
      subtitle: Text(DateTimeUtils.formatDateTime(decidedAt)),
      trailing: label.isEmpty ? null : StatusBadge(label: label, color: color),
    );
  }
}
