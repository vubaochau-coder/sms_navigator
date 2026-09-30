import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../pairing/presentation/bloc/pairing_state.dart';
import '../../../pairing/presentation/pages/paired_senders_page.dart';

/// Thẻ trạng thái kết nối ghép đôi — Soft Modern.
class ReceiverConnectionStatusCard extends StatelessWidget {
  const ReceiverConnectionStatusCard({
    super.key,
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
                    style: TextStyle(color: colorScheme.error, fontSize: 13),
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
          if (isPaired) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.cell_tower_rounded, size: 18),
                label: const Text('Xem hiện trạng thiết bị gửi (Chỉ xem)'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PairedSendersPage(),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Thẻ hướng dẫn khi chưa ghép đôi — Soft Modern.
class ReceiverNotPairedCard extends StatelessWidget {
  const ReceiverNotPairedCard({super.key, required this.onScanQr});

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
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
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
