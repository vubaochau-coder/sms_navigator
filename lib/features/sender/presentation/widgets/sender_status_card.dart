import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/sender_bloc.dart';
import '../bloc/sender_event.dart';
import '../bloc/sender_state.dart';

/// Thẻ trạng thái chuyển tiếp — Soft Modern.
class SenderStatusCard extends StatelessWidget {
  const SenderStatusCard({super.key, required this.state});

  final SenderState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = state.isRelayEnabled && state.isPaired;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.success : colorScheme.outline,
          width: isActive ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? AppColors.success
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isActive ? 'ĐANG CHUYỂN TIẾP NGẦM' : 'TẠM DỪNG HOẠT ĐỘNG',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isActive
                          ? AppColors.success
                          : colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Switch.adaptive(
                value: state.isRelayEnabled,
                activeTrackColor: AppColors.success,
                onChanged: state.isPaired
                    ? (val) {
                        context.read<SenderBloc>().add(
                          SenderToggleRelayEvent(val),
                        );
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isActive
                ? 'App đang tự động bắt SMS OTP và chuyển tiếp sang Máy Nhận qua kết nối mã hóa E2EE.'
                : (state.isPaired
                      ? 'Bật công tắc phía trên để bắt đầu chuyển tiếp OTP.'
                      : 'Thiết bị chưa được ghép đôi. Vui lòng ghép đôi với Máy Nhận để kích hoạt.'),
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          if (state.lastDetectedOtp != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                Icon(Icons.flash_on, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vừa bắt được OTP: ${state.lastDetectedOtp} (từ ${state.lastDetectedSender})',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Banner cảnh báo tối ưu pin — Soft Modern.
class SenderBatteryOptimizationBanner extends StatelessWidget {
  const SenderBatteryOptimizationBanner({super.key, required this.onRequest});

  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.battery_alert,
                color: AppColors.warning,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Cho phép chạy ngầm (Quan trọng)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Hệ thống Android (đặc biệt là Xiaomi, Samsung, Oppo) có thể tắt app khi tắt màn hình. Cần tắt tối ưu pin để nhận SMS liên tục.',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: onRequest,
            child: const Text(
              'Bật Chạy Ngầm Ngay',
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
