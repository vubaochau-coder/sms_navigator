abstract class DeviceSetupRepository {
  Future<bool> isSmsPermissionGranted();
  Future<bool> isSmsPermissionPermanentlyDenied();
  Future<bool> requestSmsPermission();
  Future<bool> openAppSettings();
  Future<bool> isBatteryOptimizationIgnored();
  Future<bool> requestIgnoreBatteryOptimization();
  Future<Map<String, dynamic>> getAggressiveRomInfo();
  Future<bool> openAutostartSettings();
  Future<bool> isAutostartAcknowledged();
  Future<bool> acknowledgeAutostart();
  Future<bool> shouldPromptSmsPermission();
  Future<bool> setDontPromptDeviceSetup();
}
