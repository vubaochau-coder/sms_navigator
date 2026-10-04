import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../core/extensions/context_extensions.dart';
import '../bloc/sms_bloc.dart';
import 'sms_tile_view.dart';

export 'sms_tile_view.dart';

class MessageListView extends StatelessWidget {
  const MessageListView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SmsBloc, SmsState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.messages.isEmpty) {
          return SmsEmptyPane(date: state.selectedDate);
        }
        return RefreshIndicator(
          onRefresh: () async {
            context.read<SmsBloc>().add(const SmsLoadDataEvent());
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 96),
            itemCount: state.messages.length,
            itemBuilder: (context, index) =>
                SmsTileView(message: state.messages[index]),
          ),
        );
      },
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
          const Icon(Icons.sms_outlined, size: 56, color: Colors.grey),
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
