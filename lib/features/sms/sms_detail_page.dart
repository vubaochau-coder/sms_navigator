import 'package:flutter/material.dart';

import '../../core/extensions/context_extensions.dart';
import '../../core/models/channel_message_model.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/utils/toast_utils.dart';

/// Màn hình hiển thị chi tiết tin nhắn SMS nhận được qua kênh E2EE.
class SmsDetailPage extends StatelessWidget {
  const SmsDetailPage({super.key, required this.message});

  final ChannelMessageModel message;

  /// Điều hướng tới màn hình chi tiết tin nhắn SMS.
  static Future<void> navigate(
    BuildContext context,
    ChannelMessageModel message,
  ) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SmsDetailPage(message: message),
      ),
    );
  }

  void _copy(BuildContext context, String content) {
    ToastUtils.copyToClipboard(
      content,
      context: context,
      successMessage: context.l10n.smsCopied(content),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final hasContent = message.decryptedOtp != null;
    final contentText =
        hasContent ? message.decryptedOtp! : l10n.smsDecryptError;

    final receivedDate = DateTimeUtils.tryParse(message.serverReceivedAt);
    final formattedTime = DateTimeUtils.formatDate(
      receivedDate,
      pattern: 'HH:mm:ss · dd/MM/yyyy',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.smsDetailTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tiêu đề: Icon kênh, Tên kênh
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.message_rounded,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message.channelName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Hàng meta: Đầu số/Brand gửi, Thời gian nhận, Thiết bị
              Row(
                children: [
                  if (message.sender != null && message.sender!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        message.sender!,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    Icons.access_time_rounded,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    formattedTime,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (message.senderDeviceId.isNotEmpty) ...[
                    const SizedBox(width: 12),
                    Icon(
                      Icons.phone_android_rounded,
                      size: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        message.senderDeviceId,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              // Tiêu đề nội dung
              Text(
                l10n.content,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              // Hộp nội dung tin nhắn (Selectable)
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 120),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                child: SelectableText(
                  contentText,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    fontWeight: hasContent ? FontWeight.w500 : FontWeight.w400,
                    color:
                        hasContent ? colorScheme.onSurface : colorScheme.error,
                  ),
                ),
              ),
              if (hasContent) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: Text(
                      l10n.copy,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _copy(context, contentText),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
