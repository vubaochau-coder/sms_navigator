import 'package:equatable/equatable.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../domain/models/decrypted_otp_item.dart';

class OtpListState extends Equatable {
  final bool isLoading;
  final DateTime selectedDate;
  final DateTime focusedDate;
  final CalendarFormat calendarFormat;
  final bool isGroupingByDevice;
  final List<DecryptedOtpItem> items;
  final String? errorMessage;

  OtpListState({
    this.isLoading = false,
    DateTime? selectedDate,
    DateTime? focusedDate,
    this.calendarFormat = CalendarFormat.week,
    this.isGroupingByDevice = false,
    this.items = const [],
    this.errorMessage,
  }) : selectedDate = selectedDate ?? DateTime.now(),
       focusedDate = focusedDate ?? (selectedDate ?? DateTime.now());

  Map<String, List<DecryptedOtpItem>> get groupedByDevice {
    final Map<String, List<DecryptedOtpItem>> map = {};
    for (final item in items) {
      final key = item.senderDeviceName.isNotEmpty
          ? item.senderDeviceName
          : (item.senderDeviceId.isNotEmpty
                ? item.senderDeviceId
                : 'Thiết bị gửi');
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  OtpListState copyWith({
    bool? isLoading,
    DateTime? selectedDate,
    DateTime? focusedDate,
    CalendarFormat? calendarFormat,
    bool? isGroupingByDevice,
    List<DecryptedOtpItem>? items,
    String? errorMessage,
  }) {
    return OtpListState(
      isLoading: isLoading ?? this.isLoading,
      selectedDate: selectedDate ?? this.selectedDate,
      focusedDate: focusedDate ?? this.focusedDate,
      calendarFormat: calendarFormat ?? this.calendarFormat,
      isGroupingByDevice: isGroupingByDevice ?? this.isGroupingByDevice,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    selectedDate,
    focusedDate,
    calendarFormat,
    isGroupingByDevice,
    items,
    errorMessage,
  ];
}
