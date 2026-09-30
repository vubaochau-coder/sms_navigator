import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/receiver_bloc.dart';
import '../bloc/receiver_event.dart';
import '../bloc/receiver_state.dart';
import '../../data/models/received_otp_model.dart';

/// Section danh sách OTP gần đây cho máy nhận.
class ReceiverRecentOtpsSection extends StatelessWidget {
  const ReceiverRecentOtpsSection({super.key, required this.onCopyOtp});

  final void Function(BuildContext context, String otp) onCopyOtp;

  @override
  Widget build(BuildContext context) {
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
                      context.read<ReceiverBloc>().add(
                        const ReceiverClearHistoryEvent(),
                      );
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
                    onCopy: () => onCopyOtp(context, item.otp),
                  );
                },
              ),
          ],
        );
      },
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
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
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
