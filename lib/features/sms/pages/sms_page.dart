import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../core/models/channel_message_model.dart';
import '../../../core/repositories/sms_by_date_repository.dart';
import '../../../core/utils/toast_utils.dart';
import '../bloc/sms_bloc.dart';

/// Màn hình SMS theo ngày (MOBILE_FEATURES 6.1–6.4):
/// - Chọn ngày trên calendar (6.1);
/// - SMS/OTP gộp của TẤT CẢ kênh đang tham gia, mỗi dòng ghi rõ kênh nguồn (6.2);
/// - Thông báo SMS/OTP mới (FCM chuông) mở thẳng màn này (6.3);
/// - Trạng thái rỗng hiển thị rõ ràng (6.4).
class SmsPage extends StatelessWidget {
  const SmsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SmsBloc(repository: context.read<SmsByDateRepository>())
            ..add(SmsDateSelected(DateTime.now())),
      child: const _SmsView(),
    );
  }
}

class _SmsView extends StatelessWidget {
  const _SmsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SmsBloc, SmsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Tin nhắn SMS theo ngày'),
            actions: [
              if (state.hasFetchedOnce)
                IconButton(
                  tooltip: 'Làm mới',
                  icon: const Icon(Icons.refresh),
                  onPressed: () =>
                      context.read<SmsBloc>().add(const SmsRefreshed()),
                ),
            ],
          ),
          body: Column(
            children: [
              _CalendarCard(selectedDate: state.selectedDate),
              Expanded(child: _MessageList(state: state)),
            ],
          ),
        );
      },
    );
  }
}

class _CalendarCard extends StatelessWidget {
  const _CalendarCard({required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 18, 12, 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
        child: TableCalendar<DateTime>(
          firstDay: DateTime.now().subtract(const Duration(days: 29)),
          lastDay: DateTime.now(),
          focusedDay: selectedDate,
          selectedDayPredicate: (day) => isSameDay(day, selectedDate),
          calendarFormat: CalendarFormat.week,
          availableGestures: AvailableGestures.horizontalSwipe,
          headerVisible: false,
          daysOfWeekHeight: 20,
          locale: 'vi_VN',
          onDaySelected: (selected, focused) {
            context.read<SmsBloc>().add(SmsDateSelected(selected));
          },
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.state});

  final SmsState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.messages.isEmpty) {
      return _EmptyPane(date: state.selectedDate);
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
            _SmsTile(message: state.messages[index]),
      ),
    );
  }
}

class _EmptyPane extends StatelessWidget {
  const _EmptyPane({required this.date});

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
            'Ngày ${DateFormat('dd/MM/yyyy').format(date)} chưa có tin nhắn SMS nào',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SmsTile extends StatelessWidget {
  const _SmsTile({required this.message});

  final ChannelMessageModel message;

  @override
  Widget build(BuildContext context) {
    final hasContent = message.decryptedOtp != null;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          hasContent ? Icons.sms_outlined : Icons.error_outline,
          color: hasContent ? Theme.of(context).colorScheme.primary : Colors.orange,
          size: 28,
        ),
        title: Text(
          hasContent ? message.decryptedOtp! : 'Không giải mã được tin này',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
            color: hasContent ? null : Colors.orange,
          ),
        ),
        subtitle: Text(
          'Kênh: ${message.channelName} · ${DateFormat('HH:mm:ss').format(_parse(message.serverReceivedAt))}',
        ),
        trailing: hasContent
            ? IconButton(
                tooltip: 'Copy',
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
      successMessage: 'Đã copy: ${message.decryptedOtp}',
    );
  }
}

// Backward compatibility typedefs
typedef SmsByDatePage = SmsPage;
typedef OtpByDatePage = SmsPage;
