import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/dimens.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/fcm_notification_service.dart';
import '../../../../core/widgets/server_settings_dialog.dart';
import '../../../notification_test/presentation/pages/notification_test_page.dart';
import '../../../otp_list/presentation/pages/otp_list_page.dart';
import '../../../pairing/presentation/bloc/pairing_bloc.dart';
import '../../../pairing/presentation/bloc/pairing_event.dart';
import '../../../pairing/presentation/bloc/pairing_state.dart';
import '../../../pairing/presentation/pages/pairing_receiver_page.dart';
import '../../data/models/received_otp_model.dart';
import '../bloc/receiver_bloc.dart';
import '../bloc/receiver_event.dart';
import '../bloc/receiver_state.dart';

class ReceiverDashboardPage extends StatefulWidget {
  const ReceiverDashboardPage({super.key});

  @override
  State<ReceiverDashboardPage> createState() => _ReceiverDashboardPageState();
}

class _ReceiverDashboardPageState extends State<ReceiverDashboardPage> {
  static const Duration _pollInterval = Duration(seconds: 3);

  Timer? _pollTimer;
  StreamSubscription<ReceivedOtpModel>? _fcmSubscription;
  final Set<String> _knownOtpIds = <String>{};
  bool _hasSyncedOtpHistory = false;

  @override
  void initState() {
    super.initState();
    context.read<ReceiverBloc>().add(const ReceiverLoadOtpsEvent());
    context.read<PairingBloc>().add(const PairingCheckReceiverStatusEvent());

    _fcmSubscription = FcmNotificationService.onOtpReceived.listen((otp) {
      if (!mounted) return;
      context.read<ReceiverBloc>().add(ReceiverNewOtpPushedEvent(otp));
    });

    _pollTimer = Timer.periodic(_pollInterval, (_) {
      if (!mounted) return;
      context.read<ReceiverBloc>().add(const ReceiverPollPendingOtpsEvent());
    });
  }

  @override
  void dispose() {
    _fcmSubscription?.cancel();
    _fcmSubscription = null;
    _pollTimer?.cancel();
    _pollTimer = null;
    super.dispose();
  }

  void _showServerSettingsDialog() {
    final di = DependencyContainer.instance;
    showDialog(
      context: context,
      builder: (_) => ServerSettingsDialog(
        deviceStorageService: di.deviceStorageService,
        nativeRelayService: di.nativeRelayService,
      ),
    );
  }

  void _handleOtpListChanged(ReceiverState state) {
    if (!_hasSyncedOtpHistory) {
      _hasSyncedOtpHistory = true;
      _knownOtpIds.addAll(state.otps.map((o) => o.id));
      return;
    }
    if (state.otps.isEmpty) {
      _knownOtpIds.clear();
      return;
    }

    final freshOtps =
        state.otps.where((o) => !_knownOtpIds.contains(o.id)).toList();
    _knownOtpIds.addAll(state.otps.map((o) => o.id));
    if (freshOtps.isEmpty) return;

    final newest = freshOtps.first;
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('OTP mới từ ${newest.sender}: ${newest.otp}'),
        duration: const Duration(seconds: 3),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Máy Nhận (Malaysia)'),
        actions: [
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
            onPressed: _showServerSettingsDialog,
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
        listener: (context, state) => _handleOtpListChanged(state),
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
                  _ConnectionStatusCard(
                    pairingState: pairingState,
                    onDisconnect: () => _showDisconnectDialog(context),
                  ),
                  const SizedBox(height: 16),
                  if (!isPaired) ...[
                    _NotPairedCard(
                      onScanQr: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PairingReceiverPage()),
                        );
                        if (!context.mounted) return;
                        context
                            .read<PairingBloc>()
                            .add(const PairingCheckReceiverStatusEvent());
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildOtpsListSection(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildOtpsListSection(BuildContext context) {
    return BlocBuilder<ReceiverBloc, ReceiverState>(
      builder: (context, state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Danh Sách OTP Gần Đây',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                if (state.otps.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      context
                          .read<ReceiverBloc>()
                          .add(const ReceiverClearHistoryEvent());
                    },
                    child: Text(
                      'Xóa Lịch Sử',
                      style: TextStyle(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.otps.isEmpty)
              const _EmptyOtpCard()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.otps.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = state.otps[index];
                  final timeStr = DateFormat('HH:mm:ss dd/MM').format(
                    DateTime.fromMillisecondsSinceEpoch(item.receivedAt),
                  );

                  return _ReceivedOtpCard(
                    otp: item,
                    timeStr: timeStr,
                    onCopy: () => _copyToClipboard(context, item.otp),
                  );
                },
              ),
          ],
        );
      },
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
}

/// Thẻ trạng thái kết nối ghép đôi — Soft Modern.
class _ConnectionStatusCard extends StatelessWidget {
  const _ConnectionStatusCard({
    required this.pairingState,
    required this.onDisconnect,
  });

  final PairingState pairingState;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isPaired = pairingState.isPaired;
    final statusColor = isPaired ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 1.5),
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
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isPaired ? 'SẴN SÀNG NHẬN OTP' : 'CHƯA GHÉP ĐÔI',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: statusColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (isPaired)
                TextButton(
                  onPressed: onDisconnect,
                  child: Text(
                    'Hủy Kết Nối',
                    style: TextStyle(
                      color: colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isPaired
                ? 'Đã kết nối an toàn (E2EE) với Máy Gửi tại Việt Nam. Mã OTP từ SIM Viettel sẽ tự động hiện lên đây trong vài giây.'
                : 'Bạn cần quét mã QR trên Máy Gửi để bắt đầu nhận OTP.',
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ hướng dẫn khi chưa ghép đôi — Soft Modern.
class _NotPairedCard extends StatelessWidget {
  const _NotPairedCard({required this.onScanQr});

  final VoidCallback onScanQr;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        children: [
          Icon(Icons.link, size: 48, color: colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'Chưa Ghép Đôi Với Thiết Bị',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nhấn nút dưới đây để quét mã QR hiển thị trên Máy Gửi (Việt Nam).',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner, size: 18),
              label: const Text('Quét Mã Ghép Đôi'),
              onPressed: onScanQr,
            ),
          ),
        ],
      ),
    );
  }
}

/// Trạng thái trống danh sách OTP — Soft Modern.
class _EmptyOtpCard extends StatelessWidget {
  const _EmptyOtpCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: colorScheme.outline),
          const SizedBox(height: 12),
          Text(
            'Chưa có mã OTP nào',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Khi hệ thống bên ngoài gửi SMS đến SIM Viettel, mã OTP sẽ tự động xuất hiện tại đây.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Thẻ OTP đã nhận — Soft Modern.
class _ReceivedOtpCard extends StatelessWidget {
  const _ReceivedOtpCard({
    required this.otp,
    required this.timeStr,
    required this.onCopy,
  });

  final ReceivedOtpModel otp;
  final String timeStr;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isExpired = otp.isExpired;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpired
              ? colorScheme.outline
              : colorScheme.primary.withValues(alpha: 0.3),
          width: isExpired ? 1 : 1.5,
        ),
        boxShadow: isExpired
            ? null
            : [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  otp.sender,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              Text(
                timeStr,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  otp.otp,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 4,
                    fontFamily: 'monospace',
                    color: isExpired
                        ? colorScheme.onSurfaceVariant
                        : colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('SAO CHÉP'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isExpired
                      ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                      : colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: onCopy,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
