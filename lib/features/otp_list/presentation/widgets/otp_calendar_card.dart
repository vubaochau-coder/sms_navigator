import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:table_calendar/table_calendar.dart';
import '../bloc/otp_list_bloc.dart';
import '../bloc/otp_list_event.dart';
import '../bloc/otp_list_state.dart';

/// Bộ lọc Date Picker bằng TableCalendar — Tự quản lý state thông qua OtpListBloc.
class OtpCalendarCard extends StatelessWidget {
  const OtpCalendarCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<OtpListBloc, OtpListState>(
      buildWhen: (previous, current) =>
          previous.focusedDate != current.focusedDate ||
          previous.selectedDate != current.selectedDate ||
          previous.calendarFormat != current.calendarFormat,
      builder: (context, state) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: TableCalendar(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: state.focusedDate,
            calendarFormat: state.calendarFormat,
            selectedDayPredicate: (day) => isSameDay(state.selectedDate, day),
            onDaySelected: (selectedDay, focusedDay) {
              context.read<OtpListBloc>().add(
                    OtpListSelectDateEvent(
                      selectedDay: selectedDay,
                      focusedDay: focusedDay,
                    ),
                  );
            },
            onFormatChanged: (format) {
              context.read<OtpListBloc>().add(
                    OtpListChangeFormatEvent(format),
                  );
            },
            onPageChanged: (focusedDay) {
              context.read<OtpListBloc>().add(
                    OtpListChangeFocusedDayEvent(focusedDay),
                  );
            },
            startingDayOfWeek: StartingDayOfWeek.monday,
            headerStyle: HeaderStyle(
              headerPadding: const EdgeInsets.only(top: 4, bottom: 4),
              formatButtonVisible: true,
              titleCentered: true,
              formatButtonShowsNext: false,
              formatButtonDecoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colorScheme.primary.withAlpha(80)),
              ),
              formatButtonTextStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
              titleTextStyle: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              leftChevronIcon: Icon(
                Icons.chevron_left_rounded,
                color: colorScheme.primary,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.primary,
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              selectedDecoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
              ),
              selectedTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onPrimary,
              ),
              todayDecoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(40),
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.primary),
              ),
              todayTextStyle: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
              defaultTextStyle: TextStyle(color: colorScheme.onSurface),
              weekendTextStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        );
      },
    );
  }
}
