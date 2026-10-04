import '../models/whitelist_config_model.dart';

abstract class NativeRelayService {
  Future<Map<String, dynamic>> getRelayConfig();
  Future<bool> setRelayConfig({
    bool? isRelayEnabled,
    String? pairId,
    String? sharedSecretBase64,
    String? relayUrl,
    String? deviceToken,
    String? deviceId,
  });
  Future<WhitelistConfigModel> getWhitelist();
  Future<bool> setWhitelist(WhitelistConfigModel config);
  Future<List<Map<String, dynamic>>> getRecentLogs();
  Future<bool> clearPairing();
  Future<bool> isBatteryOptimizationIgnored();
  Future<bool> requestIgnoreBatteryOptimization();
  Future<Map<String, dynamic>> getAggressiveRomInfo();
  Future<String?> getDeviceName();
  Future<bool> openAutostartSettings();
  void setOnOtpDetectedListener(Function(String sender, String otp) listener);
}
