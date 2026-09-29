import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../pairing/presentation/pages/pairing_sender_page.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Máy Gửi (Việt Nam)'),
        actions: [
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
                backgroundColor: AppColors.error,
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
                _buildStatusCard(context, state),
                const SizedBox(height: 16),
                if (!state.isBatteryOptimizationIgnored) ...[
                  _buildBatteryOptimizationBanner(context),
                  const SizedBox(height: 16),
                ],
                _buildPairingCard(context, state),
                const SizedBox(height: 16),
                _buildRecentLogsSection(context, state),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(BuildContext context, SenderState state) {
    final isActive = state.isRelayEnabled && state.isPaired;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? AppColors.success : AppColors.border,
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
                      color: isActive ? AppColors.success : AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isActive ? 'ĐANG CHUYỂN TIẾP NGẦM' : 'TẠM DỪNG HOẠT ĐỘNG',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isActive ? AppColors.success : AppColors.textMuted,
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
                        context
                            .read<SenderBloc>()
                            .add(SenderToggleRelayEvent(val));
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
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          if (state.lastDetectedOtp != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                const Icon(Icons.flash_on, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vừa bắt được OTP: ${state.lastDetectedOtp} (từ ${state.lastDetectedSender})',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppColors.primary,
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

  Widget _buildBatteryOptimizationBanner(BuildContext context) {
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
          const Row(
            children: [
              Icon(Icons.battery_alert, color: AppColors.warning, size: 22),
              SizedBox(width: 8),
              Text(
                'Cho phép chạy ngầm (Quan trọng)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Hệ thống Android (đặc biệt là Xiaomi, Samsung, Oppo) có thể tắt app khi tắt màn hình. Cần tắt tối ưu pin để nhận SMS liên tục.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () {
              context
                  .read<SenderBloc>()
                  .add(const SenderRequestBatteryOptimizationEvent());
            },
            child: const Text('Bật Chạy Ngầm Ngay', style: TextStyle(fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildPairingCard(BuildContext context, SenderState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thông Tin Ghép Đôi',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              if (state.isPaired)
                TextButton(
                  onPressed: () {
                    _showUnpairDialog(context);
                  },
                  child: const Text(
                    'Hủy Ghép Đôi',
                    style: TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (state.isPaired) ...[
            _buildInfoRow('Mã Kênh (Pair ID):', state.pairId),
            const SizedBox(height: 4),
            _buildInfoRow('ID Thiết Bị:', state.deviceId.substring(0, 8)),
          ] else ...[
            const Text(
              'Chưa có thiết bị Malaysia nào được kết nối với máy này.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
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

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'monospace',
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentLogsSection(BuildContext context, SenderState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Nhật Ký Chuyển Tiếp Gần Đây',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        if (state.logs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'Chưa có hoạt động chuyển tiếp OTP nào.',
                style: TextStyle(fontSize: 13, color: AppColors.textMuted),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.logs.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final log = state.logs[index];
              final isSuccess = log.status == 'SUCCESS';
              final timeStr = DateFormat('HH:mm:ss dd/MM').format(
                DateTime.fromMillisecondsSinceEpoch(log.timestamp),
              );

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
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
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'OTP: ${log.otp.length > 2 ? "${log.otp.substring(0, 2)}****" : log.otp}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _showUnpairDialog(BuildContext context) {
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
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
