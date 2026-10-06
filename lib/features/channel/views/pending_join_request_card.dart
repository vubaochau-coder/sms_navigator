import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/models/pairing_request_model.dart';
import '../../../core/utils/dialog_utils.dart';
import '../bloc/channel_bloc.dart';

/// Thẻ hiển thị một yêu cầu tham gia kênh đang chờ Owner duyệt.
class PendingJoinRequestCard extends StatelessWidget {
  const PendingJoinRequestCard({super.key, required this.request});

  final PairingRequestModel request;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final channelName = request.channelName.isNotEmpty
        ? request.channelName
        : l10n.channelNameHint;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.hourglass_top_rounded,
                color: theme.colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    channelName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      l10n.channelPendingBadge,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                side: BorderSide(
                  color: theme.colorScheme.error.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => _cancelRequest(context),
              child: Text(l10n.joinCancelRequestAction),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelRequest(BuildContext context) async {
    final l10n = context.l10n;
    final confirmed = await DialogUtils.showConfirmDialog(
      context: context,
      title: l10n.joinCancelConfirmTitle,
      message: l10n.joinCancelConfirmMessage,
      confirmText: l10n.joinCancelRequestAction,
      cancelText: l10n.joinContinueWaitingAction,
      isDestructive: true,
      icon: Icons.cancel_outlined,
    );
    if (confirmed && context.mounted) {
      context.read<ChannelBloc>().add(
        ChannelPendingJoinCancelled(request.requestId),
      );
    }
  }
}
