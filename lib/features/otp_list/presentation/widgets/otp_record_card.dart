import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../domain/models/decrypted_otp_item.dart';

/// Card hiển thị chi tiết mã OTP / SMS trong danh sách.
class OtpRecordCard extends StatelessWidget {
  const OtpRecordCard({
    super.key,
    required this.item,
    required this.onCopyOtp,
    required this.onViewDetail,
  });

  final DecryptedOtpItem item;
  final VoidCallback onCopyOtp;
  final VoidCallback onViewDetail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeStr = DateTimeUtils.formatTime(
      item.receivedAt,
      includeSeconds: true,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.sender,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    timeStr,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.phone_android_rounded,
                    size: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    item.senderDeviceName,
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    item.otp == 'SMS' ? 'THÔNG BÁO SMS' : item.otp,
                    style: TextStyle(
                      fontSize: item.otp == 'SMS' ? 14 : 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: item.otp == 'SMS' ? 0.5 : 2.0,
                      fontFamily: item.otp == 'SMS' ? null : 'monospace',
                      color: item.otp == 'SMS'
                          ? colorScheme.secondary
                          : AppColors.success,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  if (item.otp != 'SMS' && item.otp != '******')
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 14),
                      label: const Text(
                        'Sao chép mã',
                        style: TextStyle(fontSize: 11),
                      ),
                      onPressed: onCopyOtp,
                    ),
                  const SizedBox(width: 6),
                  IconButton.outlined(
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    tooltip: 'Xem toàn bộ tin nhắn',
                    style: IconButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(6),
                    ),
                    onPressed: onViewDetail,
                  ),
                ],
              ),
            ],
          ),
          if (item.fullMessage.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              item.fullMessage,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
