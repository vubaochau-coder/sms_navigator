import 'package:equatable/equatable.dart';

class DeviceProfileState extends Equatable {
  final String deviceName;
  final String deviceId;
  final bool isLoading;
  final bool isRenaming;

  const DeviceProfileState({
    this.deviceName = 'Thiết bị của tôi',
    this.deviceId = '',
    this.isLoading = false,
    this.isRenaming = false,
  });

  DeviceProfileState copyWith({
    String? deviceName,
    String? deviceId,
    bool? isLoading,
    bool? isRenaming,
  }) {
    return DeviceProfileState(
      deviceName: deviceName ?? this.deviceName,
      deviceId: deviceId ?? this.deviceId,
      isLoading: isLoading ?? this.isLoading,
      isRenaming: isRenaming ?? this.isRenaming,
    );
  }

  @override
  List<Object?> get props => [deviceName, deviceId, isLoading, isRenaming];
}
