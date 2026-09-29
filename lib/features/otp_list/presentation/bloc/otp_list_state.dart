import 'package:equatable/equatable.dart';
import '../../domain/models/decrypted_otp_item.dart';

class OtpListState extends Equatable {
  final bool isLoading;
  final DateTime selectedDate;
  final bool isGroupingByDevice;
  final List<DecryptedOtpItem> items;
  final String? errorMessage;

  const OtpListState({
    this.isLoading = false,
    required this.selectedDate,
    this.isGroupingByDevice = false,
    this.items = const [],
    this.errorMessage,
  });

  Map<String, List<DecryptedOtpItem>> get groupedByDevice {
    final Map<String, List<DecryptedOtpItem>> map = {};
    for (final item in items) {
      final key = item.senderDeviceName.isNotEmpty
          ? item.senderDeviceName
          : (item.senderDeviceId.isNotEmpty ? item.senderDeviceId : 'Thiết bị gửi');
      map.putIfAbsent(key, () => []).add(item);
    }
    return map;
  }

  OtpListState copyWith({
    bool? isLoading,
    DateTime? selectedDate,
    bool? isGroupingByDevice,
    List<DecryptedOtpItem>? items,
    String? errorMessage,
  }) {
    return OtpListState(
      isLoading: isLoading ?? this.isLoading,
      selectedDate: selectedDate ?? this.selectedDate,
      isGroupingByDevice: isGroupingByDevice ?? this.isGroupingByDevice,
      items: items ?? this.items,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        selectedDate,
        isGroupingByDevice,
        items,
        errorMessage,
      ];
}
