import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/models/activity_item.dart';
import '../../core/widgets/empty_state_view.dart';
import '../../core/widgets/relay_log_tile.dart';
import 'bloc/activity_cubit.dart';
import 'bloc/activity_state.dart';
import 'views/activity_filter_bar.dart';
import 'views/channel_activity_tile.dart';

/// Tab Hoạt động: SMS máy này đã chuyển tiếp / chặn + sự kiện của các kênh.
/// [ActivityCubit] do màn chính cung cấp (làm mới mỗi lần mở tab).
class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.activityTabTitle),
        actions: [
          IconButton(
            tooltip: l10n.refresh,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<ActivityCubit>().refresh(),
          ),
        ],
      ),
      body: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ActivityFilterBar(),
          Expanded(child: _ActivityList()),
        ],
      ),
    );
  }
}

class _ActivityList extends StatelessWidget {
  const _ActivityList();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ActivityCubit, ActivityState>(
      builder: (context, state) {
        final items = state.visibleItems;
        if (!state.hasLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: () => context.read<ActivityCubit>().refresh(),
          child: items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    const SizedBox(height: 48),
                    EmptyStateView(
                      icon: Icons.timeline_rounded,
                      title: context.l10n.activityEmptyTitle,
                      message: context.l10n.activityEmptyMessage,
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) => switch (items[index]) {
                    RelayActivityItem(:final entry) => RelayLogTile(entry: entry),
                    ChannelActivityItem(:final entry) => ChannelActivityTile(entry: entry),
                  },
                ),
        );
      },
    );
  }
}
