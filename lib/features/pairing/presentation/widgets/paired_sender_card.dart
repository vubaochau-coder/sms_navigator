import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_common_widgets.dart';
import '../../data/models/paired_device_item.dart';

/// Thẻ hiển thị thiết bị gửi đã ghép đôi (Chỉ xem).
class PairedSenderCard extends StatelessWidget {
  const PairedSenderCard({
    super.key,
    required this.item,
  });

  final PairedDeviceItem item;

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.platform?.toLowerCase() == 'ios'
                      ? Icons.phone_iphone_rounded
                      : Icons.phone_android_rounded,
                  size: 22,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.displayName,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Platform: ${item.platform ?? "Android"}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              StatusBadge.active(label: context.l10n.statusSenderMaintaining),
            ],
          ),
          const Divider(height: 14),
          PlainInfoRow(
            label: 'Pair ID',
            value: item.pairId,
          ),
          PlainInfoRow(
            label: 'Sender ID',
            value: item.deviceId,
          ),
          PlainInfoRow(
            label: context.l10n.pairedAt,
            value: item.formattedPairedAt,
          ),
          PlainInfoRow(
            label: context.l10n.lastReceivedAt,
            value: item.formattedLastActiveAt,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_open_rounded,
                  size: 16,
                  color: AppColors.success,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.l10n.senderMaintainingDesc,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
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
