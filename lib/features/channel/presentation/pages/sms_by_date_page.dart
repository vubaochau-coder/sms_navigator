import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/utils/dialog_utils.dart';
import '../bloc/sms_by_date_bloc.dart';
import '../../data/models/channel_message_model.dart';
import '../../data/repositories/sms_by_date_repository.dart';

/// Màn SMS của ngày (MOBILE_FEATURES 6.1–6.4):
/// - Chọn ngày trên calendar (6.1);
/// - SMS/OTP gộp của TẤT CẢ kênh đang tham gia, mỗi dòng ghi rõ kênh nguồn (6.2);
/// - Thông báo SMS/OTP mới (FCM chuông) mở thẳng màn này (6.3);
/// - Trạng thái rỗng / lỗi có thông điệp rõ (6.4).
class SmsByDatePage extends StatelessWidget {
  const SmsByDatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          SmsByDateBloc(repository: context.read<SmsByDateRepository>())
            ..add(SmsByDateSelected(DateTime.now())),
      child: const _SmsByDateView(),
    );
  }
}

class _SmsByDateView extends StatelessWidget {
  const _SmsByDateView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SmsByDateBloc, SmsByDateState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          DialogUtils.showInfoDialog(
            context: context,
            title: 'Không tải được tin nhắn',
            message: state.errorMessage!,
          );
        }
      },
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
                      context.read<SmsByDateBloc>().add(const SmsByDateRefreshed()),
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
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Padding(
        padding: const EdgeInsets.all(8),
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
            context.read<SmsByDateBloc>().add(SmsByDateSelected(selected));
          },
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.state});

  final SmsByDateState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null) {
      return _ErrorPane(
        message: state.errorMessage!,
        onRetry: () =>
            context.read<SmsByDateBloc>().add(const SmsByDateRefreshed()),
      );
    }
    if (state.messages.isEmpty) {
      return _EmptyPane(date: state.selectedDate);
    }
    return RefreshIndicator(
      onRefresh: () async {
        context.read<SmsByDateBloc>().add(const SmsByDateRefreshed());
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

class _ErrorPane extends StatelessWidget {
  const _ErrorPane({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 56, color: Colors.grey),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(message, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Thử lại'),
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
    Clipboard.setData(ClipboardData(text: message.decryptedOtp!));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã copy: ${message.decryptedOtp}'), duration: const Duration(seconds: 1)),
    );
  }
}

// Backward compatibility typedef
typedef OtpByDatePage = SmsByDatePage;
