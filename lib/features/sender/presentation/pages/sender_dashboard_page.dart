import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/constants/dimens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/crypto_helper.dart';
import '../../../../core/widgets/server_settings_dialog.dart';
import '../../../notification_test/presentation/pages/notification_test_page.dart';
import '../../../otp_list/presentation/pages/otp_list_page.dart';
import '../../../pairing/presentation/pages/paired_receivers_page.dart';
import '../bloc/sender_bloc.dart';
import '../bloc/sender_event.dart';
import '../bloc/sender_state.dart';
import '../widgets/sender_filter_config_card.dart';
import '../widgets/sender_pairing_card.dart';
import '../widgets/sender_recent_logs_section.dart';
import '../widgets/sender_status_card.dart';

/// Màn hình Máy Gửi (Việt Nam) — Thuần Stateless với BLoC.
class SenderDashboardPage extends StatelessWidget {
  const SenderDashboardPage({super.key});

  void _showServerSettingsDialog(BuildContext context) {
    final di = DependencyContainer.instance;
    showDialog(
      context: context,
      builder: (_) => ServerSettingsDialog(
        deviceStorageService: di.deviceStorageService,
        nativeRelayService: di.nativeRelayService,
      ),
    );
  }

  Future<void> _showSimulateOtpDialog(BuildContext context) async {
    final di = DependencyContainer.instance;
    final config = await di.nativeRelayService.getRelayConfig();
    final pairId = config['pairId']?.toString();
    final secret = config['sharedSecretBase64']?.toString();

    if (pairId == null || pairId.isEmpty || secret == null || secret.isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng ghép đôi thiết bị trước khi thử nghiệm.'),
        ),
      );
      return;
    }

    final senderController = TextEditingController(text: 'Vietcombank');
    final otpController = TextEditingController(
      text: (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString(),
    );

    if (!context.mounted) return;
    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.send_to_mobile_rounded),
              SizedBox(width: 8),
              Text('Mô Phỏng Gửi OTP'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: senderController,
                decoration: const InputDecoration(
                  labelText: 'Tên Ngân hàng / Dịch vụ',
                  prefixIcon: Icon(Icons.business_rounded),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: otpController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Mã OTP (6 chữ số)',
                  prefixIcon: Icon(Icons.password_rounded),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text('Hủy'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.send_rounded),
              label: const Text('Gửi Relay'),
              onPressed: () async {
                final sName = senderController.text.trim();
                final otpVal = otpController.text.trim();
                if (otpVal.isEmpty) return;

                Navigator.pop(dialogCtx);
                try {
                  final encrypted = await CryptoHelper.encryptAesGcm256(
                    plaintext: jsonEncode({
                      'sender': sName,
                      'otp': otpVal,
                      'timestamp': DateTime.now().millisecondsSinceEpoch,
                    }),
                    secretKeyBase64: secret,
                  );

                  final deviceId =
                      await di.deviceStorageService.getDeviceId() ?? 'dev_sender';
                  await di.apiClient.post(
                    ApiEndpoints.relay,
                    body: {
                      'pair_id': pairId,
                      'device_id': deviceId,
                      'encrypted_payload': encrypted['ciphertext']!,
                      'iv': encrypted['iv']!,
                      'sent_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
                      'ttl_seconds': 300,
                    },
                  );

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Đã gửi mã OTP $otpVal thành công sang máy nhận!'),
                      ),
                    );
                    context
                        .read<SenderBloc>()
                        .add(const SenderLoadStatusEvent());
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi gửi OTP: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    context.read<SenderBloc>().add(const SenderLoadStatusEvent());
    context.read<SenderBloc>().add(const SenderCheckSmsPermissionEvent());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Máy Gửi (Việt Nam)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.devices_rounded),
            tooltip: 'Danh sách thiết bị nhận',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PairedReceiversPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Danh sách OTP theo ngày',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OtpListPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_active_outlined),
            tooltip: 'Thử nghiệm Thông Báo Push',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationTestPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.send_to_mobile_rounded),
            tooltip: 'Mô phỏng gửi OTP',
            onPressed: () => _showSimulateOtpDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.dns_rounded),
            tooltip: 'Cài đặt Server',
            onPressed: () => _showServerSettingsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<SenderBloc>().add(const SenderLoadStatusEvent());
            },
          ),
        ],
      ),
      body: BlocConsumer<SenderBloc, SenderState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              context.read<SenderBloc>().add(const SenderLoadStatusEvent());
            },
            child: ListView(
              padding: Dimens.screenPadding,
              children: [
                SenderStatusCard(state: state),
                const SizedBox(height: 16),
                if (!state.isBatteryOptimizationIgnored) ...[
                  SenderBatteryOptimizationBanner(
                    onRequest: () {
                      context
                          .read<SenderBloc>()
                          .add(const SenderRequestBatteryOptimizationEvent());
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                SenderPairingCard(state: state),
                const SizedBox(height: 16),
                SenderFilterConfigCard(state: state),
                const SizedBox(height: 16),
                SenderRecentLogsSection(logs: state.logs),
              ],
            ),
          );
        },
      ),
    );
  }
}
