import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../../../core/widgets/app_common_widgets.dart';
import '../../data/models/paired_device_item.dart';
import '../bloc/paired_receivers_bloc.dart';
import '../bloc/paired_receivers_event.dart';

/// Thẻ hiển thị thiết bị nhận đã ghép đôi kèm công tắc bật/tắt gửi (Tự quản lý tương tác với BLoC).
class PairedReceiverCard extends StatelessWidget {
  const PairedReceiverCard({
    super.key,
    required this.item,
  });

  final PairedDeviceItem item;

  void _onToggleActive(BuildContext context, bool newValue) {
    BlocProvider.of<PairedReceiversBloc>(context).add(
      PairedReceiversToggleActiveEvent(
        pairId: item.pairId,
        isActive: newValue,
        displayName: item.displayName,
      ),
    );
  }

  Future<void> _confirmRevokePair(BuildContext context) async {
    final confirmed = await UiUtils.showConfirmDialog(
      context,
      title: 'Hủy kết nối thiết bị?',
      message:
          'Bạn có chắc chắn muốn ngắt kết nối với "${item.displayName}"? Thiết bị này sẽ không thể nhận OTP từ bạn nữa.',
      confirmText: 'Ngắt kết nối',
      isDestructive: true,
      icon: Icons.link_off_rounded,
    );

    if (confirmed && context.mounted) {
      BlocProvider.of<PairedReceiversBloc>(context).add(
        PairedReceiversRevokeEvent(pairId: item.pairId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isToggling = context.select<PairedReceiversBloc, bool>(
      (b) => b.state.togglingPairIds.contains(item.pairId),
    );

    return InfoCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                StatusBadge.active(label: 'Đang gửi')
              else
                StatusBadge.paused(label: 'Đã tạm dừng'),
            ],
          ),
          const Divider(height: 20),
          CopyableInfoRow(
            label: 'Pair ID',
            value: item.pairId,
            copySuccessMessage: 'Đã sao chép Pair ID',
          ),
          CopyableInfoRow(
            label: 'Device ID',
            value: item.deviceId,
            copySuccessMessage: 'Đã sao chép Device ID người nhận',
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text(
                  'Ghép đôi lúc: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  item.formattedPairedAt,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Text(
                  'Lần gửi gần nhất: ',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  item.formattedLastRelayedAt,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (isToggling)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Switch(
                      value: item.isActive,
                      activeTrackColor: AppColors.success,
                      onChanged: (val) => _onToggleActive(context, val),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    item.isActive ? 'Cho phép gửi OTP' : 'Tạm dừng gửi OTP',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: item.isActive
                          ? AppColors.success
                          : Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(
                  Icons.link_off_rounded,
                  color: AppColors.error,
                ),
                tooltip: 'Hủy ghép đôi',
                onPressed: () => _confirmRevokePair(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
