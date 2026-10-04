import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../../core/utils/dialog_utils.dart';
import '../bloc/otp_by_date_bloc.dart';
import '../../data/models/channel_message_model.dart';
import '../../data/repositories/otp_by_date_repository.dart';

/// Màn OTP của ngày (MOBILE_FEATURES 6.1–6.4):
/// - Chọn ngày trên calendar (6.1);
/// - OTP gộp của TẤT CẢ kênh đang tham gia, mỗi dòng ghi rõ kênh nguồn (6.2);
/// - Thông báo OTP mới (FCM chuông) mở thẳng màn này (6.3);
/// - Trạng thái rỗng / lỗi có thông điệp rõ (6.4).
class OtpByDatePage extends StatelessWidget {
  const OtpByDatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          OtpByDateBloc(repository: context.read<OtpByDateRepository>())
            ..add(OtpByDateSelected(DateTime.now())),
      child: const _OtpByDateView(),
    );
  }
}

class _OtpByDateView extends StatelessWidget {
  const _OtpByDateView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<OtpByDateBloc, OtpByDateState>(
      listener: (context, state) {
        if (state.errorMessage != null) {
          DialogUtils.showInfoDialog(
            context: context,
            title: 'Không tải được OTP',
            message: state.errorMessage!,
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('OTP theo ngày'),
            actions: [
              if (state.hasFetchedOnce)
                IconButton(
                  tooltip: 'Làm mới',
                  icon: const Icon(Icons.refresh),
                  onPressed: () =>
                      context.read<OtpByDateBloc>().add(const OtpByDateRefreshed()),
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
            context.read<OtpByDateBloc>().add(OtpByDateSelected(selected));
          },
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.state});

  final OtpByDateState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null) {
      return _ErrorPane(
        message: state.errorMessage!,
        onRetry: () =>
            context.read<OtpByDateBloc>().add(const OtpByDateRefreshed()),
      );
    }
    if (state.messages.isEmpty) {
      return _EmptyPane(date: state.selectedDate);
    }
    return RefreshIndicator(
      onRefresh: () async {
        context.read<OtpByDateBloc>().add(const OtpByDateRefreshed());
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
        itemCount: state.messages.length,
        itemBuilder: (context, index) =>
            _OtpTile(message: state.messages[index]),
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
            'Ngày ${DateFormat('dd/MM/yyyy').format(date)} chưa có OTP nào',
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

class _OtpTile extends StatelessWidget {
  const _OtpTile({required this.message});

  final ChannelMessageModel message;

  @override
  Widget build(BuildContext context) {
    final hasOtp = message.decryptedOtp != null;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Icon(
          hasOtp ? Icons.password_rounded : Icons.error_outline,
          color: hasOtp ? Theme.of(context).colorScheme.primary : Colors.orange,
          size: 28,
        ),
        title: Text(
          hasOtp ? message.decryptedOtp! : 'Không decrypt được tin này',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
            color: hasOtp ? null : Colors.orange,
          ),
        ),
        subtitle: Text(
          'Kênh: ${message.channelName} · ${DateFormat('HH:mm:ss').format(_parse(message.serverReceivedAt))}',
        ),
        trailing: hasOtp
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
