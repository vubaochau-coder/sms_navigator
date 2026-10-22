import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/models/channel_model.dart';
import '../../../core/widgets/whitelist_pills.dart';
import '../../channel_detail/channel_detail_page.dart';
import '../bloc/channel_bloc.dart';

class ChannelCardView extends StatelessWidget {
  const ChannelCardView({super.key, required this.channel});

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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              channel.isOwner
                  ? context.l10n.channelOwnerSubtitle(
                      channel.memberCount,
                      channel.currentEpoch,
                    )
                  : context.l10n.channelMemberSubtitle(
                      channel.ownerDeviceName,
                      channel.memberCount,
                    ),
            ),
            if (channel.whitelist != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: WhitelistPills(config: channel.whitelist!, maxPills: 3),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ChannelDetailPage(channelId: channel.channelId),
            ),
          );
          // Tên kênh / thành viên có thể đã đổi, hoặc kênh đã bị rời / giải tán.
          if (!context.mounted) return;
          try {
            context.read<ChannelBloc>().add(const ChannelLoadDataEvent());
          } on ProviderNotFoundException {
            // Card dựng ngoài ChannelPage (test / preview) — không có list để làm mới.
          }
        },
      ),
    );
  }
}
