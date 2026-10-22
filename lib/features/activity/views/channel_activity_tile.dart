import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/models/channel_activity_entry.dart';
import '../../../core/models/channel_event.dart';
import '../../../core/utils/date_time_utils.dart';

/// Một sự kiện kênh trên tab Hoạt động.
class ChannelActivityTile extends StatelessWidget {
  const ChannelActivityTile({super.key, required this.entry});

  final ChannelActivityEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = context.colorScheme;
    final channel = entry.channelName ?? l10n.activityUnknownChannel;
    final actor = entry.actorName;

    final (IconData icon, Color color, String text) = switch (entry.kind) {
      ChannelEventKind.joinRequest => (
          Icons.person_add_alt_1_rounded,
          colorScheme.primary,
          actor != null ? l10n.activityJoinRequest(actor, channel) : l10n.activityJoinRequestAnonymous(channel),
        ),
      ChannelEventKind.approved => (Icons.verified_rounded, Colors.green.shade700, l10n.activityApproved(channel)),
      ChannelEventKind.revoked when entry.isArchived => (
          Icons.archive_rounded,
          colorScheme.onSurfaceVariant,
          l10n.activityArchived(channel),
        ),
      ChannelEventKind.revoked => (Icons.no_accounts_rounded, colorScheme.error, l10n.activityRevoked(channel)),
      ChannelEventKind.memberLeft => (
          Icons.logout_rounded,
          Colors.orange.shade800,
          actor != null ? l10n.activityMemberLeft(actor, channel) : l10n.activityMemberLeftAnonymous(channel),
        ),
      _ => (Icons.info_outline_rounded, colorScheme.onSurfaceVariant, channel),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    DateTimeUtils.formatDate(entry.at, pattern: 'HH:mm:ss · dd/MM/yyyy'),
                    style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
