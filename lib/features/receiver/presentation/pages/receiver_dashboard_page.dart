import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../pairing/presentation/bloc/pairing_bloc.dart';
import '../../../pairing/presentation/bloc/pairing_event.dart';
import '../../../pairing/presentation/bloc/pairing_state.dart';
import '../../../pairing/presentation/pages/pairing_receiver_page.dart';
import '../bloc/receiver_bloc.dart';
import '../bloc/receiver_event.dart';
import '../bloc/receiver_state.dart';

class ReceiverDashboardPage extends StatefulWidget {
  const ReceiverDashboardPage({super.key});

  @override
  State<ReceiverDashboardPage> createState() => _ReceiverDashboardPageState();
}

class _ReceiverDashboardPageState extends State<ReceiverDashboardPage> {
  @override
  void initState() {
    super.initState();
    context.read<ReceiverBloc>().add(const ReceiverLoadOtpsEvent());
    context.read<PairingBloc>().add(const PairingCheckReceiverStatusEvent());
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
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ReceiverBloc>().add(const ReceiverLoadOtpsEvent());
              context.read<PairingBloc>().add(const PairingCheckReceiverStatusEvent());
            },
          ),
        ],
      ),
      body: BlocBuilder<PairingBloc, PairingState>(
        builder: (context, pairingState) {
          final isPaired = pairingState.isPaired;

          return RefreshIndicator(
            onRefresh: () async {
              context.read<ReceiverBloc>().add(const ReceiverLoadOtpsEvent());
              context.read<PairingBloc>().add(const PairingCheckReceiverStatusEvent());
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildConnectionStatusCard(context, pairingState),
                const SizedBox(height: 16),
                if (!isPaired) ...[
                  _buildNotPairedCard(context),
                  const SizedBox(height: 16),
                ],
                _buildOtpsListSection(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConnectionStatusCard(BuildContext context, PairingState pairingState) {
    final isPaired = pairingState.isPaired;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPaired ? AppColors.success : AppColors.warning,
          width: 1.5,
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
                      color: isPaired ? AppColors.success : AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isPaired ? 'SẴN SÀNG NHẬN OTP' : 'CHƯA GHÉP ĐÔI',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isPaired ? AppColors.success : AppColors.warning,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              if (isPaired)
                TextButton(
                  onPressed: () {
                    _showDisconnectDialog(context);
                  },
                  child: const Text('Hủy Kết Nối', style: TextStyle(color: AppColors.error, fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isPaired
                ? 'Đã kết nối an toàn (E2EE) với Máy Gửi tại Việt Nam. Mã OTP từ SIM Viettel sẽ tự động hiện lên đây trong vài giây.'
                : 'Bạn cần nhập mã ghép đôi 6 số từ Máy Gửi để bắt đầu nhận OTP.',
            style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildNotPairedCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          const Icon(Icons.link, size: 48, color: AppColors.primary),
          const SizedBox(height: 12),
          const Text(
            'Chưa Ghép Đôi Với Thiết Bị',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Nhấn nút dưới đây để nhập mã 6 số từ Máy Gửi (Việt Nam).',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.qr_code_scanner, size: 18),
              label: const Text('Nhập Mã Ghép Đôi'),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PairingReceiverPage()),
                );
                if (!context.mounted) return;
                context.read<PairingBloc>().add(const PairingCheckReceiverStatusEvent());
              },
            ),
          ),
        ],
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
                const Text(
                  'Danh Sách OTP Gần Đây',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (state.otps.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      context.read<ReceiverBloc>().add(const ReceiverClearHistoryEvent());
                    },
                    child: const Text('Xóa Lịch Sử', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (state.otps.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted),
                    SizedBox(height: 12),
                    Text(
                      'Chưa có mã OTP nào',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Khi hệ thống bên ngoài gửi SMS đến SIM Viettel, mã OTP sẽ tự động xuất hiện tại đây.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.otps.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = state.otps[index];
                  final isExpired = item.isExpired;
                  final timeStr = DateFormat('HH:mm:ss dd/MM').format(
                    DateTime.fromMillisecondsSinceEpoch(item.receivedAt),
                  );

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isExpired ? AppColors.border : AppColors.primary.withValues(alpha: 0.3),
                        width: isExpired ? 1 : 1.5,
                      ),
                      boxShadow: isExpired
                          ? null
                          : [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.06),
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
                                color: AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.sender,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            Text(
                              timeStr,
                              style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.otp,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 4,
                                fontFamily: 'monospace',
                                color: isExpired ? AppColors.textMuted : AppColors.textPrimary,
                              ),
                            ),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.copy, size: 16),
                              label: const Text('SAO CHÉP'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isExpired ? AppColors.textMuted : AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              ),
                              onPressed: () => _copyToClipboard(context, item.otp),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  void _showDisconnectDialog(BuildContext context) {
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<PairingBloc>().add(const PairingDisconnectReceiverEvent());
            },
            child: const Text('Hủy Kết Nối'),
          ),
        ],
      ),
    );
  }
}
