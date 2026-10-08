import 'package:flutter/material.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/models/channel_message_model.dart';
import '../../../core/utils/date_time_utils.dart';
import '../../../core/utils/toast_utils.dart';
import 'sms_detail_bottom_sheet.dart';

class SmsTileView extends StatelessWidget {
  const SmsTileView({super.key, required this.message});

  final ChannelMessageModel message;

  @override
  Widget build(BuildContext context) {
    final hasContent = message.decryptedOtp != null;
    final colorScheme = Theme.of(context).colorScheme;
    final formattedTime = DateTimeUtils.formatTime(
      DateTimeUtils.tryParse(message.serverReceivedAt),
      includeSeconds: true,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => SmsDetailBottomSheet.show(context, message),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(14, 12, hasContent ? 0 : 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: 10),
                      child: Icon(
                        Icons.message_rounded,
                        size: 18,
                        color: colorScheme.primary,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Hàng đầu tiên: Tên kênh · Brand · Thời gian (size nhỏ)
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  message.channelName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.primary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (message.sender != null &&
                                  message.sender!.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    message.sender!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.onSecondaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 6),
                              Text(
                                '· $formattedTime',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Hàng tiếp theo: Nội dung tin nhắn (size 14)
                          Text(
                            hasContent
                                ? message.decryptedOtp!
                                : context.l10n.smsDecryptError,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: hasContent
                                  ? FontWeight.w500
                                  : FontWeight.w400,
                              color: hasContent
                                  ? colorScheme.onSurface
                                  : colorScheme.error,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (hasContent)
              IconButton(
                tooltip: context.l10n.smsCopyTooltip,
                iconSize: 20,
                icon: Icon(
                  Icons.copy_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: () => _copy(context),
              ),
          ],
        ),
      ),
    );
  }

  void _copy(BuildContext context) {
    if (message.decryptedOtp == null) return;
    ToastUtils.copyToClipboard(
      message.decryptedOtp!,
      context: context,
      successMessage: context.l10n.smsCopied(message.decryptedOtp!),
    );
  }
}
