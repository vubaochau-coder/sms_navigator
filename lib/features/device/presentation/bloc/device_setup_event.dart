import 'package:equatable/equatable.dart';

abstract class DeviceSetupEvent extends Equatable {
  const DeviceSetupEvent();

  @override
  List<Object?> get props => [];
}

class DeviceSetupStarted extends DeviceSetupEvent {
  const DeviceSetupStarted();
}

class DeviceSetupSmsPermissionRequested extends DeviceSetupEvent {
  const DeviceSetupSmsPermissionRequested();
}

class DeviceSetupAppSettingsOpened extends DeviceSetupEvent {
  const DeviceSetupAppSettingsOpened();
}

class DeviceSetupBatteryOptimizationRequested extends DeviceSetupEvent {
  const DeviceSetupBatteryOptimizationRequested();
}

class DeviceSetupAutostartSettingsOpened extends DeviceSetupEvent {
  const DeviceSetupAutostartSettingsOpened();
}

class DeviceSetupAutostartAcknowledged extends DeviceSetupEvent {
  const DeviceSetupAutostartAcknowledged();
}
