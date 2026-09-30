import 'package:table_calendar/table_calendar.dart';

abstract class OtpListEvent {
  const OtpListEvent();
}

class OtpListLoadEvent extends OtpListEvent {
  const OtpListLoadEvent();
}

class OtpListToggleGroupEvent extends OtpListEvent {
  const OtpListToggleGroupEvent();
}

class OtpListChangeDateEvent extends OtpListEvent {
  final DateTime? selectedDate;
  final DateTime? focusedDate;

  const OtpListChangeDateEvent({
    this.selectedDate,
    this.focusedDate,
  });
}

class OtpListChangeFormatEvent extends OtpListEvent {
  final CalendarFormat format;

  const OtpListChangeFormatEvent(this.format);
}
