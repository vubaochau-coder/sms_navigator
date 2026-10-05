import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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

        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Yêu cầu chờ duyệt (${requests.length})',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final request in requests)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.person_add_alt_1_rounded),
                      title: Text(request.requesterDeviceName),
                      subtitle: Text(_formatTime(request.createdAt)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Từ chối',
                            icon: Icon(
                              Icons.close,
                              color: colorScheme.error,
                            ),
                            onPressed: () => _reject(context, request),
                          ),
                          IconButton(
                            tooltip: 'Duyệt',
                            icon: Icon(
                              Icons.check,
                              color: colorScheme.primary,
                            ),
                            onPressed: () => _approve(context, request),
                          ),
                        ],
                      ),
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
    DialogUtils.showConfirmDialog(
      context: context,
      title: 'Duyệt thành viên?',
      message:
          'Duyệt "${request.requesterDeviceName}" sẽ tự động xoay khóa kênh và cấp khóa mới cho mọi thành viên.',
      confirmText: 'Duyệt',
    ).then((confirmed) {
      if (confirmed && context.mounted) {
        BlocProvider.of<ChannelDetailBloc>(context)
            .add(ChannelDetailConfirmed(request));
      }
    });
  }

  void _reject(BuildContext context, PairingRequestModel request) {
    DialogUtils.showConfirmDialog(
      context: context,
      title: 'Từ chối yêu cầu?',
      message:
          'Từ chối "${request.requesterDeviceName}"? Mã QR đã dùng cho yêu cầu này sẽ không còn hiệu lực.',
      confirmText: 'Từ chối',
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
