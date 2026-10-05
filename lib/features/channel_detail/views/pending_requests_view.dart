import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/models/pairing_request_model.dart';
import '../../../core/utils/dialog_utils.dart';
import '../bloc/channel_detail_bloc.dart';

/// Danh sách các yêu cầu tham gia kênh đang chờ Owner phê duyệt.
class PendingRequestsView extends StatelessWidget {
  const PendingRequestsView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ChannelDetailBloc, ChannelDetailState, List<PairingRequestModel>>(
      selector: (state) => state.pendingRequests,
      builder: (context, requests) {
        if (requests.isEmpty) return const SizedBox.shrink();

        final l10n = context.l10n;
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.channelDetailPendingRequestsTitle(requests.length),
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemCount: requests.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final request = requests[index];
                      return ListTile(
                        dense: true,
                        visualDensity: const VisualDensity(vertical: -4),
                        minVerticalPadding: 0,
                        minTileHeight: 0,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.person_add_alt_1_rounded),
                        title: Text(request.requesterDeviceName),
                        subtitle: Text(_formatTime(request.createdAt)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              tooltip: l10n.channelDetailRejectTooltip,
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                Icons.close,
                                color: colorScheme.error,
                              ),
                              onPressed: () => _reject(context, request),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              tooltip: l10n.channelDetailApproveTooltip,
                              iconSize: 20,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                Icons.check,
                                color: colorScheme.primary,
                              ),
                              onPressed: () => _approve(context, request),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
        BlocProvider.of<ChannelDetailBloc>(context)
            .add(ChannelDetailConfirmed(request));
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
        BlocProvider.of<ChannelDetailBloc>(context)
            .add(ChannelDetailRejected(request));
      }
    });
  }

  String _formatTime(String iso) {
    final time = DateTime.tryParse(iso);
    if (time == null) return iso;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
