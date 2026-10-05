import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/models/pairing_request_model.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/utils/dialog_utils.dart';
import '../bloc/channel_detail_bloc.dart';

/// Widget hiển thị thông tin và hành động (Duyệt / Từ chối) của một yêu cầu kết nối kênh.
class PendingRequestItem extends StatelessWidget {
  const PendingRequestItem({super.key, required this.request});

  final PairingRequestModel request;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        const Icon(Icons.person_add_alt_1_rounded, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                request.requesterDeviceName,
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                DateTimeUtils.formatTime(
                  DateTimeUtils.tryParse(request.createdAt),
                ),
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: l10n.channelDetailRejectTooltip,
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.close, color: colorScheme.error),
          onPressed: () => _reject(context, request),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: l10n.channelDetailApproveTooltip,
          iconSize: 20,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          visualDensity: VisualDensity.compact,
          icon: Icon(Icons.check, color: colorScheme.primary),
          onPressed: () => _approve(context, request),
        ),
      ],
    );
  }

  void _approve(BuildContext context, PairingRequestModel request) {
    final l10n = context.l10n;
    DialogUtils.showConfirmDialog(
      context: context,
      title: l10n.channelDetailApproveDialogTitle,
      message: l10n.channelDetailApproveDialogMessage(request.requesterDeviceName),
      confirmText: l10n.channelDetailApproveConfirm,
    ).then((confirmed) {
      if (confirmed && context.mounted) {
        BlocProvider.of<ChannelDetailBloc>(
          context,
        ).add(ChannelDetailConfirmed(request));
      }
    });
  }

  void _reject(BuildContext context, PairingRequestModel request) {
    final l10n = context.l10n;
    DialogUtils.showConfirmDialog(
      context: context,
      title: l10n.channelDetailRejectDialogTitle,
      message: l10n.channelDetailRejectDialogMessage(request.requesterDeviceName),
      confirmText: l10n.channelDetailRejectConfirm,
      isDestructive: true,
    ).then((confirmed) {
      if (confirmed && context.mounted) {
        BlocProvider.of<ChannelDetailBloc>(
          context,
        ).add(ChannelDetailRejected(request));
      }
    });
  }
}
