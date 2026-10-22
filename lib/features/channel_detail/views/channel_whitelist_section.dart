import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/models/whitelist_config_model.dart';
import '../../../core/widgets/whitelist_pills.dart';
import '../../settings/whitelist_settings_page.dart';
import '../bloc/channel_detail_bloc.dart';
import '../../../core/extensions/context_extensions.dart';

/// Card thông tin & Cấu hình White-list trong màn hình Chi tiết Kênh (v2.2).
class ChannelWhitelistSection extends StatelessWidget {
  const ChannelWhitelistSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChannelDetailBloc, ChannelDetailState>(
      buildWhen: (previous, current) =>
          previous.detail != current.detail || previous.whitelist != current.whitelist,
      builder: (context, state) {
        final detail = state.detail;
        if (detail == null) return const SizedBox.shrink();
        final whitelist = state.whitelist;

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
                        context.l10n.whitelistSectionTitle,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (isOwner)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          // Bỏ vùng tap 48px mặc định để không đẩy cao Row header
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: const EdgeInsets.symmetric(horizontal: 0),
                        ),
                        icon: const Icon(Icons.settings_outlined, size: 16),
                        label: Text(context.l10n.whitelistConfigureButton),
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
                      ? context.l10n.whitelistSectionOwnerDesc
                      : context.l10n.whitelistSectionMemberDesc,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                if (whitelist != null) ...[
                  const SizedBox(height: 10),
                  ChannelWhitelistEntries(config: whitelist),
                ],
                if (detail.whitelist != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      context.l10n.whitelistVersionLabel(detail.whitelist!.whitelistVersion),
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

/// Danh sách đầy đủ người gửi trong white-list (chỉ xem) — Owner sửa qua nút "Cấu hình".
class ChannelWhitelistEntries extends StatelessWidget {
  const ChannelWhitelistEntries({super.key, required this.config});

  final WhitelistConfigModel config;

  @override
  Widget build(BuildContext context) {
    final isEmpty = config.entries.isEmpty && config.mode == WhitelistMode.explicit;
    if (isEmpty) {
      return Text(
        context.l10n.whitelistNoSenders,
        style: TextStyle(
          fontSize: 12,
          fontStyle: FontStyle.italic,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      );
    }
    return WhitelistPills(config: config, showOtpMarker: true);
  }
}
