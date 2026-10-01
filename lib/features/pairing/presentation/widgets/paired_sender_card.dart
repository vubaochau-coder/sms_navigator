import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../../core/widgets/app_common_widgets.dart';
import '../../data/models/paired_device_item.dart';
import '../bloc/paired_senders_bloc.dart';
import '../bloc/paired_senders_event.dart';

/// Thẻ hiển thị thiết bị gửi đã ghép đôi (Tự quản lý tương tác với BLoC, không truyền callback).
class PairedSenderCard extends StatelessWidget {
  const PairedSenderCard({
    super.key,
    required this.item,
  });

  final PairedDeviceItem item;

  Future<void> _confirmRevokePair(BuildContext context) async {
    final confirmed = await UiUtils.showConfirmDialog(
      context,
      title: 'Hủy kết nối máy gửi?',
      message:
          'Bạn có chắc chắn muốn ngắt kết nối với "${item.displayName}"? Bạn sẽ không nhận được OTP từ thiết bị này nữa.',
      confirmText: 'Ngắt kết nối',
      isDestructive: true,
      icon: Icons.link_off_rounded,
    );

    if (confirmed && context.mounted) {
      BlocProvider.of<PairedSendersBloc>(context).add(
        PairedSendersRevokeEvent(pairId: item.pairId),
      );
    }
  }

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
                  color: (item.isActive ? AppColors.success : AppColors.warning)
                      .withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.platform?.toLowerCase() == 'ios'
                      ? Icons.phone_iphone_rounded
                      : Icons.phone_android_rounded,
                  size: 22,
                  color: item.isActive ? AppColors.success : AppColors.warning,
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
              if (item.isActive)
                StatusBadge.active(label: 'Đang duy trì gửi')
              else
                StatusBadge.paused(label: 'Người gửi tạm dừng'),
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
            label: 'Ghép đôi lúc',
            value: item.formattedPairedAt,
          ),
          PlainInfoRow(
            label: 'Lần nhận gần nhất',
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
                  item.isActive
                      ? Icons.lock_open_rounded
                      : Icons.pause_circle_outline_rounded,
                  size: 16,
                  color: item.isActive ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.isActive
                        ? 'Người gửi đang duy trì truyền tin. (Chỉ xem)'
                        : 'Người gửi đang tạm dừng truyền tin. (Chỉ xem)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.link_off_rounded,
                    size: 20,
                    color: AppColors.error,
                  ),
                  tooltip: 'Hủy ghép đôi',
                  onPressed: () => _confirmRevokePair(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
