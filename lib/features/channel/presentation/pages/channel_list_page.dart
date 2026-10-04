import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/dialog_utils.dart';
import '../bloc/channel_bloc.dart';
import '../../data/models/channel_model.dart';
import '../../data/repositories/channel_repository.dart';
import 'channel_page.dart';

/// Màn quản lý kênh chia 2 nhóm (MOBILE_FEATURES 2.1):
/// - "Kênh của bạn" (bạn là Owner) → ChannelPage
/// - "Kênh bạn tham gia" (bạn là Member) → trang chi tiết member
class ChannelListPage extends StatelessWidget {
  const ChannelListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          ChannelBloc(repository: context.read<ChannelRepository>())
            ..add(const ChannelListLoaded()),
      child: const _ChannelListView(),
    );
  }
}

class _ChannelListView extends StatelessWidget {
  const _ChannelListView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChannelBloc, ChannelListState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          DialogUtils.showInfoDialog(
            context: context,
            title: 'Có lỗi xảy ra',
            message: state.errorMessage!,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Kênh'),
            actions: [
              IconButton(
                tooltip: 'Đổi tên thiết bị',
                icon: const Icon(Icons.badge_outlined),
                onPressed: () => _renameDevice(context),
              ),
            ],
          ),
          body: state.isLoading && state.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: () async {
                    context.read<ChannelBloc>().add(const ChannelListLoaded());
                  },
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 96),
                    children: [
                      if (state.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(top: 120),
                          child: Center(
                            child: Text(
                              'Bạn chưa tham gia kênh nào.\nTạo kênh mới hoặc quét mã mời.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      else ...[
                        _SectionHeader(title: 'Kênh của bạn', count: state.ownedChannels.length),
                        for (final channel in state.ownedChannels)
                          _ChannelCard(channel: channel),
                        _SectionHeader(title: 'Kênh bạn tham gia', count: state.joinedChannels.length),
                        for (final channel in state.joinedChannels)
                          _ChannelCard(channel: channel),
                      ],
                    ],
                  ),
                ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _createChannel(context),
            icon: const Icon(Icons.add),
            label: const Text('Tạo kênh'),
          ),
        );
      },
    );
  }

  void _createChannel(BuildContext context) {
    final controller = TextEditingController();
    DialogUtils.showCustomFormDialog<void>(
      context: context,
      title: 'Tạo kênh mới',
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 100,
        decoration: const InputDecoration(
          labelText: 'Tên kênh',
          hintText: 'Ví dụ: Kênh nhà',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            final name = controller.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop();
            context.read<ChannelBloc>().add(ChannelCreated(name));
          },
          child: const Text('Tạo'),
        ),
      ],
    );
  }

  void _renameDevice(BuildContext context) {
    final controller = TextEditingController();
    DialogUtils.showCustomFormDialog<void>(
      context: context,
      title: 'Đổi tên thiết bị',
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLength: 128,
        decoration: const InputDecoration(
          labelText: 'Tên hiển thị',
          hintText: 'Ví dụ: Pixel 8 của Minh',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () {
            final name = controller.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop();
            context.read<ChannelBloc>().add(DeviceRenamed(name));
          },
          child: const Text('Lưu'),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Text('$count', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  const _ChannelCard({required this.channel});

  final ChannelModel channel;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: Icon(
          channel.isOwner ? Icons.dns_rounded : Icons.smartphone_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          channel.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          channel.isOwner
              ? '${channel.memberCount} thành viên · epoch ${channel.currentEpoch}'
              : 'Máy chủ: ${channel.ownerDeviceName} · ${channel.memberCount} thành viên',
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ChannelPage(channelId: channel.channelId),
            ),
          );
        },
      ),
    );
  }
}
