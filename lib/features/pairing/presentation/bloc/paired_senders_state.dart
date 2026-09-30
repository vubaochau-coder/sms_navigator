import '../../data/models/paired_device_item.dart';

class PairedSendersState {
  final bool isLoading;
  final String? errorMessage;
  final List<PairedDeviceItem> devices;

  const PairedSendersState({
    this.isLoading = false,
    this.errorMessage,
    this.devices = const [],
  });

  PairedSendersState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    List<PairedDeviceItem>? devices,
  }) {
    return PairedSendersState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      devices: devices ?? this.devices,
    );
  }
}
