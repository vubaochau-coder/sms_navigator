import 'package:equatable/equatable.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../domain/models/decrypted_otp_item.dart';

enum OtpDirectionFilter { all, sent, received }

class OtpListState extends Equatable {
  final bool isLoading;
  final DateTime selectedDate;
  final DateTime focusedDate;
  final CalendarFormat calendarFormat;
  final bool isGroupingByDevice;
  final OtpDirectionFilter directionFilter;
  final List<DecryptedOtpItem> items;

  OtpListState({
    this.isLoading = false,
    DateTime? selectedDate,
    DateTime? focusedDate,
    this.calendarFormat = CalendarFormat.week,
    this.isGroupingByDevice = false,
    this.directionFilter = OtpDirectionFilter.all,
    this.items = const [],
  }) : selectedDate = selectedDate ?? DateTime.now(),
       focusedDate = focusedDate ?? (selectedDate ?? DateTime.now());

  List<DecryptedOtpItem> get filteredItems {
    switch (directionFilter) {
      case OtpDirectionFilter.all:
        return items;
      case OtpDirectionFilter.sent:
        return items
            .where((item) => item.viewerRole != 'RECEIVER')
            .toList(growable: false);
      case OtpDirectionFilter.received:
        return items
            .where((item) => item.viewerRole == 'RECEIVER')
            .toList(growable: false);
    }
  }

  Map<String, List<DecryptedOtpItem>> get groupedByDevice {
    return _groupItemsByDevice(items);
  }

  Map<String, List<DecryptedOtpItem>> get filteredGroupedByDevice {
    return _groupItemsByDevice(filteredItems);
  }

  static Map<String, List<DecryptedOtpItem>> _groupItemsByDevice(
    List<DecryptedOtpItem> items,
  ) {
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
    OtpDirectionFilter? directionFilter,
    List<DecryptedOtpItem>? items,
  }) {
    return OtpListState(
      isLoading: isLoading ?? this.isLoading,
      selectedDate: selectedDate ?? this.selectedDate,
      focusedDate: focusedDate ?? this.focusedDate,
      calendarFormat: calendarFormat ?? this.calendarFormat,
      isGroupingByDevice: isGroupingByDevice ?? this.isGroupingByDevice,
      directionFilter: directionFilter ?? this.directionFilter,
      items: items ?? this.items,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    selectedDate,
    focusedDate,
    calendarFormat,
    isGroupingByDevice,
    directionFilter,
    items,
  ];
}
