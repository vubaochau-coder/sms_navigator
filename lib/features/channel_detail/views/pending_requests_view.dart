import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/models/pairing_request_model.dart';
import '../bloc/channel_detail_bloc.dart';
import 'pending_request_item.dart';

export 'pending_request_item.dart';

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
        final textTheme = Theme.of(context).textTheme;

        return Card(
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
                  itemBuilder: (context, index) => PendingRequestItem(
                    request: requests[index],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
