import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/models/channel_message_model.dart';
import '../../../core/utils/toast_utils.dart';

class SmsTileView extends StatelessWidget {
  const SmsTileView({super.key, required this.message});

  final ChannelMessageModel message;

  @override
  Widget build(BuildContext context) {
    final hasContent = message.decryptedOtp != null;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          hasContent ? Icons.sms_outlined : Icons.error_outline,
          color: hasContent
              ? Theme.of(context).colorScheme.primary
              : Colors.orange,
          size: 28,
        ),
        title: Text(
          hasContent ? message.decryptedOtp! : context.l10n.smsDecryptError,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: hasContent ? null : Colors.orange,
          ),
        ),
        subtitle: Text(
          context.l10n.smsChannelPrefix(
            message.channelName,
            DateFormat('HH:mm:ss').format(_parse(message.serverReceivedAt)),
          ),
        ),
        trailing: hasContent
            ? IconButton(
                tooltip: context.l10n.smsCopyTooltip,
                icon: const Icon(Icons.copy_rounded),
                onPressed: () => _copy(context),
              )
            : null,
      ),
    );
  }

  DateTime _parse(String iso) =>
      DateTime.tryParse(iso) ?? DateTime.fromMillisecondsSinceEpoch(0);

  void _copy(BuildContext context) {
    if (message.decryptedOtp == null) return;
    ToastUtils.copyToClipboard(
      message.decryptedOtp!,
      context: context,
      successMessage: context.l10n.smsCopied(message.decryptedOtp!),
    );
  }
}
