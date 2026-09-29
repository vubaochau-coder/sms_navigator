import '../models/relay_log_model.dart';
import '../services/native_relay_service.dart';

abstract class SenderRepository {
  Future<Map<String, dynamic>> getRelayStatus();
  Future<bool> setRelayEnabled(bool isEnabled);
  Future<bool> setRelayMode(String relayMode);
  Future<bool> setSenderWhitelist(List<String> whitelist);
  Future<List<RelayLogModel>> getRecentLogs();
  Future<bool> checkBatteryOptimization();
  Future<bool> requestBatteryOptimization();
  Future<bool> unpairDevice();
  void registerOtpListener(Function(String sender, String otp) listener);
}

class SenderRepositoryImpl implements SenderRepository {
  final NativeRelayService nativeService;

  SenderRepositoryImpl({required this.nativeService});

  @override
  Future<Map<String, dynamic>> getRelayStatus() async {
    return await nativeService.getRelayConfig();
  }

  @override
  Future<bool> setRelayEnabled(bool isEnabled) async {
    return await nativeService.setRelayConfig(isRelayEnabled: isEnabled);
  }

  @override
  Future<bool> setRelayMode(String relayMode) async {
    return await nativeService.setRelayConfig(relayMode: relayMode);
  }

  @override
  Future<bool> setSenderWhitelist(List<String> whitelist) async {
    return await nativeService.setRelayConfig(senderWhitelist: whitelist);
  }

  @override
  Future<List<RelayLogModel>> getRecentLogs() async {
    final rawLogs = await nativeService.getRecentLogs();
    return rawLogs.map((map) => RelayLogModel.fromMap(map)).toList();
  }

  @override
  Future<bool> checkBatteryOptimization() async {
    return await nativeService.isBatteryOptimizationIgnored();
  }

  @override
  Future<bool> requestBatteryOptimization() async {
    return await nativeService.requestIgnoreBatteryOptimization();
  }

  @override
  Future<bool> unpairDevice() async {
    return await nativeService.clearPairing();
  }

  @override
  void registerOtpListener(Function(String sender, String otp) listener) {
    nativeService.setOnOtpDetectedListener(listener);
  }
}
