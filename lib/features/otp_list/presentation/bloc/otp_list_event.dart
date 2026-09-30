import 'package:table_calendar/table_calendar.dart';

abstract class OtpListEvent {
  const OtpListEvent();
}

class OtpListLoadEvent extends OtpListEvent {
  final DateTime date;
  final String? pairId;

  const OtpListLoadEvent({required this.date, this.pairId});
}

class OtpListToggleGroupEvent extends OtpListEvent {
  const OtpListToggleGroupEvent();
}

class OtpListChangeDateEvent extends OtpListEvent {
  final DateTime selectedDate;

  const OtpListChangeDateEvent(this.selectedDate);
}

class OtpListSelectDateEvent extends OtpListEvent {
  final DateTime selectedDay;
  final DateTime focusedDay;

  const OtpListSelectDateEvent({
    required this.selectedDay,
    required this.focusedDay,
  });
}

class OtpListChangeFormatEvent extends OtpListEvent {
  final CalendarFormat format;

  const OtpListChangeFormatEvent(this.format);
}

class OtpListChangeFocusedDayEvent extends OtpListEvent {
  final DateTime focusedDay;

  const OtpListChangeFocusedDayEvent(this.focusedDay);
}
