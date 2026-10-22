import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/repositories/backup_repository.dart';
import '../../core/repositories/channel_repository.dart';
import '../../core/repositories/join_channel_repository.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/services/startup_reconcile_service.dart';
import '../../core/usecases/sync_owner_relay_channel_use_case.dart';
import '../../core/ui/dialog_utils.dart';
import '../backup/bloc/backup_reminder_cubit.dart';
import '../backup/views/backup_reminder_banner.dart';
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
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: _createChannelBloc),
        BlocProvider(create: _createReminder),
      ],
      child: const _ChannelPageView(),
    );
  }

  static BackupReminderCubit _createReminder(BuildContext context) {
    T? optional<T>() {
      try {
        return context.read<T>();
      } catch (_) {
        return null;
      }
    }

    return BackupReminderCubit(
      backupRepository: optional<BackupRepository>(),
      localStorage: optional<LocalStorageService>(),
    );
  }

  static ChannelBloc _createChannelBloc(BuildContext context) {
    StartupReconcileService? reconcile;
    try {
      reconcile = context.read<StartupReconcileService>();
    } catch (_) {
      reconcile = null;
    }
    SyncOwnerRelayChannelUseCase? syncUseCase;
    try {
      syncUseCase = context.read<SyncOwnerRelayChannelUseCase>();
    } catch (_) {
      syncUseCase = null;
    }
    return ChannelBloc(
      repository: context.read<ChannelRepository>(),
      joinRepository: context.read<JoinChannelRepository>(),
      reconcileService: reconcile,
      syncUseCase: syncUseCase,
    )..add(const ChannelLoadDataEvent());
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
        body: BlocListener<ChannelBloc, ChannelState>(
          listenWhen: (previous, current) =>
              previous.ownedChannels != current.ownedChannels || previous.joinedChannels != current.joinedChannels,
          listener: (context, state) => context.read<BackupReminderCubit>().update([
            for (final channel in state.ownedChannels) channel.channelId,
            for (final channel in state.joinedChannels) channel.channelId,
          ]),
          child: const Column(
            children: [
              BackupReminderBanner(),
              Expanded(
                child: TabBarView(
                  children: [
                    OwnedChannelListView(),
                    JoinedChannelListView(),
                  ],
                ),
              ),
            ],
          ),
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
