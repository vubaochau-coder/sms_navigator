import 'package:equatable/equatable.dart';

class DeviceSetupState extends Equatable {
  final bool isLoading;
  final bool? smsPermissionGranted;
  final bool smsPermissionPermanentlyDenied;
  final bool? batteryUnrestricted;
  final bool isAggressiveRom;
  final String? oemName;
  final bool autostartScreenOpened;
  final bool autostartAcknowledged;

  const DeviceSetupState({
    this.isLoading = false,
    this.smsPermissionGranted,
    this.smsPermissionPermanentlyDenied = false,
    this.batteryUnrestricted,
    this.isAggressiveRom = false,
    this.oemName,
    this.autostartScreenOpened = false,
    this.autostartAcknowledged = false,
  });

  bool get isAllCriticalStepsDone =>
      smsPermissionGranted == true && batteryUnrestricted == true;

  DeviceSetupState copyWith({
    bool? isLoading,
    bool? smsPermissionGranted,
    bool? smsPermissionPermanentlyDenied,
    bool? batteryUnrestricted,
    bool? isAggressiveRom,
    String? oemName,
    bool? autostartScreenOpened,
    bool? autostartAcknowledged,
  }) {
    return DeviceSetupState(
      isLoading: isLoading ?? this.isLoading,
      smsPermissionGranted: smsPermissionGranted ?? this.smsPermissionGranted,
      smsPermissionPermanentlyDenied:
          smsPermissionPermanentlyDenied ?? this.smsPermissionPermanentlyDenied,
      batteryUnrestricted: batteryUnrestricted ?? this.batteryUnrestricted,
      isAggressiveRom: isAggressiveRom ?? this.isAggressiveRom,
      oemName: oemName ?? this.oemName,
      autostartScreenOpened: autostartScreenOpened ?? this.autostartScreenOpened,
      autostartAcknowledged: autostartAcknowledged ?? this.autostartAcknowledged,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    smsPermissionGranted,
    smsPermissionPermanentlyDenied,
    batteryUnrestricted,
    isAggressiveRom,
    oemName,
    autostartScreenOpened,
    autostartAcknowledged,
  ];
}
