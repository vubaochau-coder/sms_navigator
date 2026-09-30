import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

/// Bộ lọc Date Picker bằng TableCalendar — Tuỳ biến sâu theo Soft Modern Theme.
class OtpCalendarCard extends StatelessWidget {
  const OtpCalendarCard({
    super.key,
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
  });

  final DateTime focusedDay;
  final DateTime selectedDay;
  final CalendarFormat calendarFormat;
  final OnDaySelected onDaySelected;
  final ValueChanged<CalendarFormat> onFormatChanged;
  final ValueChanged<DateTime> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2030, 12, 31),
        focusedDay: focusedDay,
        calendarFormat: calendarFormat,
        selectedDayPredicate: (day) => isSameDay(selectedDay, day),
        onDaySelected: onDaySelected,
        onFormatChanged: onFormatChanged,
        onPageChanged: onPageChanged,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: HeaderStyle(
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
          leftChevronIcon:
              Icon(Icons.chevron_left_rounded, color: colorScheme.primary),
          rightChevronIcon:
              Icon(Icons.chevron_right_rounded, color: colorScheme.primary),
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
  }
}
