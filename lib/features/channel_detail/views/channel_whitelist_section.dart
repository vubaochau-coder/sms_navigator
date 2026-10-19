import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/channel_detail_model.dart';
import '../../settings/whitelist_settings_page.dart';
import '../bloc/channel_detail_bloc.dart';

/// Card thông tin & Cấu hình White-list trong màn hình Chi tiết Kênh (v2.2).
class ChannelWhitelistSection extends StatelessWidget {
  const ChannelWhitelistSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<ChannelDetailBloc, ChannelDetailState, ChannelDetailModel?>(
      selector: (state) => state.detail,
      builder: (context, detail) {
        if (detail == null) return const SizedBox.shrink();

        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;
        final isOwner = detail.isOwner;

        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.filter_list_rounded,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bộ lọc tin nhắn (White-list)',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isOwner)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        icon: const Icon(Icons.settings_outlined, size: 16),
                        label: const Text('Cấu hình'),
                        onPressed: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => WhitelistSettingsPage(
                                channelId: detail.channelId,
                                channelName: detail.name,
                              ),
                            ),
                          );
                          // Refresh detail khi quay về
                          if (context.mounted) {
                            context.read<ChannelDetailBloc>().add(
                                  ChannelDetailLoaded(detail.channelId),
                                );
                          }
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isOwner
                      ? 'Thiết lập danh sách số điện thoại/Brandname được phép chuyển tiếp tin nhắn SMS và OTP qua kênh này.'
                      : 'Kênh này được bảo vệ bởi bộ lọc của Chủ kênh. Tin nhắn SMS sẽ được chuyển tiếp theo cấu hình bảo mật đã duyệt.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                if (detail.whitelist != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Phiên bản bộ lọc: v${detail.whitelist!.whitelistVersion}',
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
