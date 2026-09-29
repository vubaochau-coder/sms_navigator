import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/widgets/server_settings_dialog.dart';
import '../../../pairing/presentation/pages/pairing_sender_page.dart';
import '../../data/models/relay_log_model.dart';
import '../bloc/sender_bloc.dart';
import '../bloc/sender_event.dart';
import '../bloc/sender_state.dart';

class SenderDashboardPage extends StatefulWidget {
  const SenderDashboardPage({super.key});

  @override
  State<SenderDashboardPage> createState() => _SenderDashboardPageState();
}

class _SenderDashboardPageState extends State<SenderDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<SenderBloc>().add(const SenderLoadStatusEvent());
    _checkSmsPermission();
  }

  Future<void> _checkSmsPermission() async {
    final status = await Permission.sms.status;
    if (!status.isGranted) {
      await Permission.sms.request();
    }
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

  @override
  Widget build(BuildContext context) {    return Scaffold(
      appBar: AppBar(
        title: const Text('Máy Gửi (Việt Nam)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dns_rounded),
            tooltip: 'Cài đặt Server',
            onPressed: _showServerSettingsDialog,
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
              padding: const EdgeInsets.all(16),
              children: [
                _StatusCard(state: state),
                const SizedBox(height: 16),
                if (!state.isBatteryOptimizationIgnored) ...[
                  _BatteryOptimizationBanner(
                    onRequest: () {
                      context
                          .read<SenderBloc>()
                          .add(const SenderRequestBatteryOptimizationEvent());
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                _PairingCard(state: state),
                const SizedBox(height: 16),
                _RecentLogsSection(logs: state.logs),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Thẻ trạng thái chuyển tiếp — Soft Modern.
class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.state});

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
                        context.read<SenderBloc>().add(SenderToggleRelayEvent(val));
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
class _BatteryOptimizationBanner extends StatelessWidget {
  const _BatteryOptimizationBanner({required this.onRequest});

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
              const Icon(Icons.battery_alert, color: AppColors.warning, size: 22),
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
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: onRequest,
            child: const Text('Bật Chạy Ngầm Ngay', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

/// Thẻ thông tin ghép đôi — Soft Modern.
class _PairingCard extends StatelessWidget {
  const _PairingCard({required this.state});

  final SenderState state;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Thông Tin Ghép Đôi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: colorScheme.onSurface,
                ),
              ),
              if (state.isPaired)
                TextButton(
                  onPressed: () {
                    _UnpairDialog.show(context);
                  },
                  child: Text(
                    'Hủy Ghép Đôi',
                    style: TextStyle(color: colorScheme.error, fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (state.isPaired) ...[
            _InfoRow(
              label: 'Mã Kênh (Pair ID):',
              value: state.pairId,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 4),
            _InfoRow(
              label: 'ID Thiết Bị:',
              value: state.deviceId.substring(0, 8),
              colorScheme: colorScheme,
            ),
          ] else ...[
            Text(
              'Chưa có thiết bị Malaysia nào được kết nối với máy này.',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.qr_code, size: 18),
                label: const Text('Tạo Mã Ghép Đôi'),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PairingSenderPage(),
                    ),
                  );
                  if (!context.mounted) return;
                  context.read<SenderBloc>().add(const SenderLoadStatusEvent());
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Dialog xác nhận hủy ghép đôi.
class _UnpairDialog {
  static void show(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Hủy Ghép Đôi?'),
        content: const Text(
          'Thiết bị sẽ ngừng chuyển tiếp OTP đến Máy Nhận. Bạn có chắc chắn muốn hủy không?',
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
              context.read<SenderBloc>().add(const SenderUnpairEvent());
            },
            child: const Text('Hủy Ghép Đôi'),
          ),
        ],
      ),
    );
  }
}

/// Một dòng thông tin label — value trong thẻ ghép đôi.
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.colorScheme,
  });

  final String label;
  final String value;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

/// Danh sách nhật ký chuyển tiếp gần đây — Soft Modern.
class _RecentLogsSection extends StatelessWidget {
  const _RecentLogsSection({required this.logs});

  final List<RelayLogModel> logs;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Nhật Ký Chuyển Tiếp Gần Đây',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        if (logs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outline),
            ),
            child: Center(
              child: Text(
                'Chưa có hoạt động chuyển tiếp OTP nào.',
                style: TextStyle(
                  fontSize: 13,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: logs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final log = logs[index];
              final timeStr = DateFormat('HH:mm:ss dd/MM').format(
                DateTime.fromMillisecondsSinceEpoch(log.timestamp),
              );

              return _RelayLogTile(log: log, timeStr: timeStr);
            },
          ),
      ],
    );
  }
}

/// Một dòng nhật ký chuyển tiếp — Soft Modern.
class _RelayLogTile extends StatelessWidget {
  const _RelayLogTile({required this.log, required this.timeStr});

  final RelayLogModel log;
  final String timeStr;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSuccess = log.status == 'SUCCESS';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isSuccess ? AppColors.successLight : AppColors.errorLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check : Icons.warning_amber_rounded,
              color: isSuccess ? AppColors.success : AppColors.error,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      log.sender,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: 11,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'OTP: ${log.otp.length > 2 ? "${log.otp.substring(0, 2)}****" : log.otp}',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    fontFamily: 'monospace',
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
