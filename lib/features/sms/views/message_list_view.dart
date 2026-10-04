import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/models/channel_message_model.dart';
import '../../../core/utils/toast_utils.dart';
import '../bloc/sms_bloc.dart';

class MessageListView extends StatelessWidget {
  const MessageListView({super.key, required this.state});

  final SmsState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.messages.isEmpty) {
      return SmsEmptyPane(date: state.selectedDate);
    }
    return RefreshIndicator(
      onRefresh: () async {
        context.read<SmsBloc>().add(const SmsRefreshed());
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
        itemCount: state.messages.length,
        itemBuilder: (context, index) =>
            SmsTile(message: state.messages[index]),
      ),
    );
  }
}

class SmsEmptyPane extends StatelessWidget {
  const SmsEmptyPane({super.key, required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Text(
            context.l10n.smsEmptyInDate(DateFormat('dd/MM/yyyy').format(date)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class SmsTile extends StatelessWidget {
  const SmsTile({super.key, required this.message});

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
