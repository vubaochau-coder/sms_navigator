import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

import '../bloc/sms_bloc.dart';

class CalendarCardView extends StatelessWidget {
  const CalendarCardView({super.key, required this.selectedDate});

  final DateTime selectedDate;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
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
