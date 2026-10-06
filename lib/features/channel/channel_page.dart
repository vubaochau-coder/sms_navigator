import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/repositories/channel_repository.dart';
import '../../core/repositories/join_channel_repository.dart';
import '../../core/utils/dialog_utils.dart';
import '../device/views/device_profile_button.dart';
import 'bloc/channel_bloc.dart';
import 'views/channel_list_view.dart';

/// Màn quản lý kênh chia 2 nhóm (MOBILE_FEATURES 2.1):
/// - "Kênh của bạn" (bạn là Owner) → ChannelDetailPage
/// - "Kênh bạn tham gia" (bạn là Member) → trang chi tiết member
class ChannelPage extends StatelessWidget {
  const ChannelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        return ChannelBloc(
          repository: context.read<ChannelRepository>(),
          joinRepository: context.read<JoinChannelRepository>(),
        )..add(const ChannelLoadDataEvent());
      },
      child: const _ChannelPageView(),
    );
  }
}

class _ChannelPageView extends StatelessWidget {
  const _ChannelPageView();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.channelPageTitle),
          actions: const [
            DeviceProfileButton(),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: l10n.channelOwnedSectionTitle),
              Tab(text: l10n.channelJoinedSectionTitle),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            OwnedChannelListView(),
            JoinedChannelListView(),
          ],
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 24),
          child: FloatingActionButton.extended(
            heroTag: 'channel_list_create_channel_fab',
            onPressed: () => _createChannel(context),
            icon: const Icon(Icons.add),
            label: Text(l10n.channelCreateAction),
          ),
        ),
      ),
    );
  }

  Future<void> _createChannel(BuildContext context) async {
    final l10n = context.l10n;
    final name = await DialogUtils.showInputDialog(
      context: context,
      title: l10n.channelCreateDialogTitle,
      labelText: l10n.channelNameLabel,
      hintText: l10n.channelNameHint,
      maxLength: 100,
      icon: Icons.add_circle_outline_rounded,
      confirmText: l10n.channelCreateConfirm,
      cancelText: l10n.cancel,
    );
    if (name != null && name.isNotEmpty && context.mounted) {
      context.read<ChannelBloc>().add(ChannelCreated(name));
    }
  }
}
