import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/models/channel_model.dart';
import '../../channel_detail/channel_detail_page.dart';

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
        subtitle: Text(
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
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => ChannelDetailPage(channelId: channel.channelId),
            ),
          );
        },
      ),
    );
  }
}
