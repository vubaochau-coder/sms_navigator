import '../../data/models/paired_device_item.dart';

class PairedReceiversState {
  final bool isLoading;
  final String? errorMessage;
  final List<PairedDeviceItem> devices;

  const PairedReceiversState({
    this.isLoading = false,
    this.errorMessage,
    this.devices = const [],
  });

  PairedReceiversState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<PairedDeviceItem>? devices,
  }) {
    return PairedReceiversState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      devices: devices ?? this.devices,
    );
  }
}
