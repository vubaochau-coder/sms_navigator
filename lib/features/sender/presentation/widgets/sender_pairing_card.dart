import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../pairing/presentation/pages/paired_receivers_page.dart';
import '../../../pairing/presentation/pages/pairing_sender_page.dart';
import '../bloc/sender_bloc.dart';
import '../bloc/sender_event.dart';
import '../bloc/sender_state.dart';

/// Thẻ thông tin ghép đôi — Soft Modern.
class SenderPairingCard extends StatelessWidget {
  const SenderPairingCard({super.key, required this.state});

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
                    SenderUnpairDialog.show(context);
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
              value: state.deviceId.length >= 8
                  ? state.deviceId.substring(0, 8)
                  : state.deviceId,
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.devices_rounded, size: 18),
                label: const Text('Quản lý thiết bị nhận (Bật/Tắt gửi)'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PairedReceiversPage(),
                    ),
                  );
                },
              ),
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
class SenderUnpairDialog {
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
