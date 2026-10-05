import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/channel_detail_model.dart';
import '../bloc/channel_detail_bloc.dart';

/// Card tóm tắt thông tin kênh: tên, Owner, số thành viên, epoch hiện tại.
class ChannelSummaryView extends StatelessWidget {
  const ChannelSummaryView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ChannelDetailBloc, ChannelDetailState, ChannelDetailModel?>(
      selector: (state) => state.detail,
      builder: (context, detail) {
        if (detail == null) return const SizedBox.shrink();

        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.dns_rounded,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        detail.name,
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Máy chủ (Owner): ${detail.ownerDeviceName}'),
                const SizedBox(height: 4),
                Text('${detail.memberCount} thành viên'),
                const SizedBox(height: 4),
                Text('Epoch hiện tại: ${detail.currentEpoch}'),
              ],
            ),
          ),
        );
      },
    );
  }
}
