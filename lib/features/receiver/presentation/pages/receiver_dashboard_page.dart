import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/dimens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/server_settings_dialog.dart';
import '../../../notification_test/presentation/pages/notification_test_page.dart';
import '../../../otp_list/presentation/pages/otp_list_page.dart';
import '../../../pairing/presentation/bloc/pairing_bloc.dart';
import '../../../pairing/presentation/bloc/pairing_event.dart';
import '../../../pairing/presentation/bloc/pairing_state.dart';
import '../../../pairing/presentation/pages/paired_senders_page.dart';
import '../../../pairing/presentation/pages/pairing_receiver_page.dart';
import '../bloc/receiver_bloc.dart';
import '../bloc/receiver_event.dart';
import '../bloc/receiver_state.dart';
import '../widgets/receiver_connection_status_card.dart';
import '../widgets/receiver_recent_otps_section.dart';

/// Màn hình Máy Nhận (Malaysia) — Thuần Stateless với BLoC.
class ReceiverDashboardPage extends StatelessWidget {
  const ReceiverDashboardPage({super.key});

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

  void _copyToClipboard(BuildContext context, String otp) {
    Clipboard.setData(ClipboardData(text: otp));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép mã OTP: $otp'),
        backgroundColor: AppColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showDisconnectDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hủy Kết Nối?'),
        content: const Text(
          'Thiết bị sẽ không còn nhận OTP từ Máy Gửi nữa. Bạn có chắc chắn không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Giữ Lại'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context
                  .read<PairingBloc>()
                  .add(const PairingDisconnectReceiverEvent());
            },
            child: const Text('Hủy Kết Nối'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Đảm bảo sync được kích hoạt khi màn hình mở
    context.read<ReceiverBloc>().add(const ReceiverStartSyncEvent());
    context.read<PairingBloc>().add(const PairingCheckReceiverStatusEvent());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Máy Nhận (Malaysia)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cell_tower_rounded),
            tooltip: 'Thiết bị gửi (Xem trạng thái)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PairedSendersPage()),
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
            icon: const Icon(Icons.dns_rounded),
            tooltip: 'Cài đặt Server',
            onPressed: () => _showServerSettingsDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ReceiverBloc>().add(const ReceiverLoadOtpsEvent());
              context
                  .read<PairingBloc>()
                  .add(const PairingCheckReceiverStatusEvent());
            },
          ),
        ],
      ),
      body: BlocListener<ReceiverBloc, ReceiverState>(
        listenWhen: (previous, current) =>
            current.latestPushedOtp != null &&
            current.latestPushedOtp != previous.latestPushedOtp,
        listener: (context, state) {
          final otp = state.latestPushedOtp!;
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('OTP mới từ ${otp.sender}: ${otp.otp}'),
              duration: const Duration(seconds: 3),
            ),
          );
        },
        child: BlocBuilder<PairingBloc, PairingState>(
          builder: (context, pairingState) {
            final isPaired = pairingState.isPaired;

            return RefreshIndicator(
              onRefresh: () async {
                context
                    .read<ReceiverBloc>()
                    .add(const ReceiverLoadOtpsEvent());
                context
                    .read<PairingBloc>()
                    .add(const PairingCheckReceiverStatusEvent());
              },
              child: ListView(
                padding: Dimens.screenPadding,
                children: [
                  ReceiverConnectionStatusCard(
                    pairingState: pairingState,
                    onDisconnect: () => _showDisconnectDialog(context),
                  ),
                  const SizedBox(height: 16),
                  if (!isPaired) ...[
                    ReceiverNotPairedCard(
                      onScanQr: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PairingReceiverPage()),
                        );
                        if (context.mounted) {
                          context
                              .read<PairingBloc>()
                              .add(const PairingCheckReceiverStatusEvent());
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  ReceiverRecentOtpsSection(
                    onCopyOtp: _copyToClipboard,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
