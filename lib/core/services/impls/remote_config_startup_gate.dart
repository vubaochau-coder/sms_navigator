import 'package:firebase_remote_config/firebase_remote_config.dart';

import '../../utils/app_logger.dart';
import '../startup_gate.dart';

/// [StartupGate] đọc `maintenance_enabled` / `maintenance_message` từ
/// Firebase Remote Config. Fetch bị giới hạn [fetchTimeout] để không kéo dài
/// màn khởi động; fetch lỗi → dùng giá trị đã kích hoạt lần trước (nếu có).
class RemoteConfigStartupGate implements StartupGate {
  RemoteConfigStartupGate({
    FirebaseRemoteConfig? remoteConfig,
    this.fetchTimeout = const Duration(seconds: 4),
  }) : _remoteConfig = remoteConfig;

  static const String enabledKey = 'maintenance_enabled';
  static const String messageKey = 'maintenance_message';

  FirebaseRemoteConfig? _remoteConfig;
  final Duration fetchTimeout;

  @override
  Future<StartupGateResult> check() async {
    final FirebaseRemoteConfig config;
    try {
      config = _remoteConfig ??= FirebaseRemoteConfig.instance;
      await config.setDefaults(const <String, dynamic>{
        enabledKey: false,
        messageKey: '',
      });
    } catch (e) {
      // Firebase chưa khởi tạo (test / bản dựng không có Firebase) → mở cổng
      return const StartupGateResult.open();
    }

    try {
      await config.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: fetchTimeout,
        minimumFetchInterval: const Duration(minutes: 1),
      ));
      await config.fetchAndActivate().timeout(fetchTimeout);
    } catch (e) {
      AppLogger.w('StartupGate', 'Remote Config fetch failed, using last activated values', e);
    }

    try {
      if (!config.getBool(enabledKey)) return const StartupGateResult.open();
      return StartupGateResult.maintenance(config.getString(messageKey).trim());
    } catch (e) {
      return const StartupGateResult.open();
    }
  }
}
