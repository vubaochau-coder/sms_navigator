import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/dimens.dart';
import '../cubit/notification_test_cubit.dart';
import '../cubit/notification_test_state.dart';
import '../widgets/notification_info_cards.dart';
import '../widgets/notification_mockup_cards.dart';
import '../widgets/notification_presets_selector.dart';

/// Màn hình thử nghiệm Push Notification — Thuần Stateless với BLoC.
class NotificationTestPage extends StatelessWidget {
  const NotificationTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationTestCubit()..loadStatus(),
      child: const _NotificationTestView(),
    );
  }
}

class _NotificationTestView extends StatelessWidget {
  const _NotificationTestView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thử Nghiệm Push Notification'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle_rounded),
            tooltip: 'Sinh mã OTP ngẫu nhiên',
            onPressed: () {
              context.read<NotificationTestCubit>().randomizeOtp();
            },
          ),
        ],
      ),
      body: BlocConsumer<NotificationTestCubit, NotificationTestState>(
        listener: (context, state) {
          if (state.toastMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.toastMessage!),
                backgroundColor: state.isErrorToast
                    ? colorScheme.error
                    : AppColors.success,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        builder: (context, state) {
          return ListView(
            padding: Dimens.screenPadding,
            children: [
              NotificationHeaderCard(colorScheme: colorScheme),
              const SizedBox(height: 12),
              if (!state.hasNotificationPermission) ...[
                NotificationPermissionWarningCard(
                  onRequestPermission: () {
                    context
                        .read<NotificationTestCubit>()
                        .requestPermission();
                  },
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 12),
              ],
              NotificationSectionTitle(
                title: '1. UI Thông Báo Máy Nhận (B) — Khi Có OTP Đến',
                subtitle:
                    'Mô phỏng trải nghiệm Heads-up Notification khi nhận OTP',
                icon: Icons.mark_chat_unread_rounded,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 8),
              ReceiverNotificationMockup(
                sender: state.sender,
                otp: state.otp,
                rawMessage: state.rawMessage,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 8),
              Text(
                'Ngân hàng Việt Nam:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              BankPresetsSelector(
                presets: NotificationPresetsData.bankPresets,
                selected: state.sender,
                onSelected: (val) {
                  context
                      .read<NotificationTestCubit>()
                      .selectBankPreset(val);
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Mẫu Tiếng Trung & Toàn bộ SMS:',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 4),
              ChinesePresetsSelector(
                currentSender: state.sender,
                currentOtp: state.otp,
                onSelected: (item) {
                  context
                      .read<NotificationTestCubit>()
                      .selectChinesePreset(item);
                },
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.success,
                ),
                icon: const Icon(Icons.notifications_active_rounded),
                label: Text(
                  state.isLoading
                      ? 'Đang phát thông báo...'
                      : 'Bắn Thử Thông Báo Nhận OTP (Device B)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: state.isLoading
                    ? null
                    : () {
                        context
                            .read<NotificationTestCubit>()
                            .triggerReceiverNotification();
                      },
              ),
              const SizedBox(height: 20),
              NotificationSectionTitle(
                title: '2. UI Thông Báo Máy Gửi (A) — Chuyển Tiếp Thành Công',
                subtitle:
                    'Mô phỏng trạng thái thông báo xác nhận gửi OTP sang B',
                icon: Icons.send_rounded,
                color: colorScheme.secondary,
              ),
              const SizedBox(height: 8),
              SenderNotificationMockup(
                sender: state.sender,
                otp: state.otp,
                targetDevice: state.targetDevice,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text(
                  'Bắn Thử Thông Báo Gửi Thành Công (Device A)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: state.isLoading
                    ? null
                    : () {
                        context
                            .read<NotificationTestCubit>()
                            .triggerSenderNotification();
                      },
              ),
              const SizedBox(height: 20),
              FcmStatusCard(
                fcmToken: state.fcmToken,
                hasPermission: state.hasNotificationPermission,
                colorScheme: colorScheme,
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }
}
