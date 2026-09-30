import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/utils/date_time_utils.dart';
import '../../../../core/utils/ui_utils.dart';
import '../../domain/models/decrypted_otp_item.dart';
import 'otp_detail_bottom_sheet.dart';

/// Card hiển thị chi tiết mã OTP / SMS trong danh sách.
class OtpRecordCard extends StatelessWidget {
  const OtpRecordCard({
    super.key,
    required this.item,
  });

  final DecryptedOtpItem item;

  void _copyToClipboard(BuildContext context) {
    HapticFeedback.lightImpact();
    final l10n = context.l10n;
    final message = l10n.otpCopiedMessage(item.otp);
    UiUtils.copyToClipboard(item.otp, successMessage: message);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
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
                    item.otp == 'SMS'
                        ? l10n.otpSmsNotification
                        : item.otp,
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
                      label: Text(
                        l10n.otpCopyAction,
                        style: const TextStyle(fontSize: 11),
                      ),
                      onPressed: () => _copyToClipboard(context),
                    ),
                  const SizedBox(width: 6),
                  IconButton.outlined(
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    tooltip: l10n.otpViewFullMessage,
                    style: IconButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.all(6),
                    ),
                    onPressed: () => OtpDetailBottomSheet.show(context, item),
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
