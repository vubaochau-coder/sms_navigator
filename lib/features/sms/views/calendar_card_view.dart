import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';

import '../bloc/sms_bloc.dart';

class CalendarCardView extends StatelessWidget {
  const CalendarCardView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<SmsBloc, SmsState, DateTime>(
      selector: (state) => state.selectedDate,
      builder: (context, selectedDate) {
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12),
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
      },
    );
  }
}
