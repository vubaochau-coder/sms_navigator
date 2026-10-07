import '../models/whitelist_config_model.dart';

abstract class NativeRelayService {
  Future<Map<String, dynamic>> getRelayConfig();
  Future<WhitelistConfigModel> getWhitelist();
  Future<bool> setWhitelist(WhitelistConfigModel config);
  Future<List<Map<String, dynamic>>> getRecentLogs();
  Future<bool> isBatteryOptimizationIgnored();
  Future<bool> requestIgnoreBatteryOptimization();
  Future<bool> setActiveRelayChannel({
    required String channelId,
    required String channelName,
    required int keyEpoch,
    required String channelKeyBase64,
    required String deviceToken,
    String? apiBaseUrl,
  });
  Future<bool> clearActiveRelayChannel();
  Future<Map<String, dynamic>> getAggressiveRomInfo();
  Future<String?> getDeviceName();
  Future<bool> openAutostartSettings();
}
