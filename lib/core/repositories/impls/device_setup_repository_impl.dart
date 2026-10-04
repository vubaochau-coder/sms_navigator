import '../../services/device_setup_service.dart';
import '../device_setup_repository.dart';

class DeviceSetupRepositoryImpl implements DeviceSetupRepository {
  final DeviceSetupService deviceSetupService;

  DeviceSetupRepositoryImpl({required this.deviceSetupService});

  @override
  Future<bool> isSmsPermissionGranted() =>
      deviceSetupService.isSmsPermissionGranted();

  @override
  Future<bool> isSmsPermissionPermanentlyDenied() =>
      deviceSetupService.isSmsPermissionPermanentlyDenied();

  @override
  Future<bool> requestSmsPermission() =>
      deviceSetupService.requestSmsPermission();

  @override
  Future<bool> openAppSettings() => deviceSetupService.openAppSettings();

  @override
  Future<bool> isBatteryOptimizationIgnored() =>
      deviceSetupService.isBatteryOptimizationIgnored();

  @override
  Future<bool> requestIgnoreBatteryOptimization() =>
      deviceSetupService.requestIgnoreBatteryOptimization();

  @override
  Future<Map<String, dynamic>> getAggressiveRomInfo() =>
      deviceSetupService.getAggressiveRomInfo();

  @override
  Future<bool> openAutostartSettings() =>
      deviceSetupService.openAutostartSettings();

  @override
  Future<bool> isAutostartAcknowledged() =>
      deviceSetupService.isAutostartAcknowledged();

  @override
  Future<bool> acknowledgeAutostart() =>
      deviceSetupService.acknowledgeAutostart();

  @override
  Future<bool> shouldPromptSmsPermission() =>
      deviceSetupService.shouldPromptSmsPermission();

  @override
  Future<bool> setDontPromptDeviceSetup() =>
      deviceSetupService.setDontPromptDeviceSetup();
}
