import 'package:flutter/foundation.dart';

import '../l10n/app_l10n.dart';
import '../ui/toast_utils.dart';
import '../utils/app_logger.dart';
import 'device_api_service.dart';
import 'device_storage_service.dart';
import 'relay_channel_bridge.dart';

/// Xử lý 401 tập trung (BACKLOG 3.2): `ApiClient` gọi [call] khi một request
/// bị từ chối vì device token. Đăng ký lại với **cùng** `device_id` + public
/// key — server cấp token mới cho đúng thiết bị đó, membership / envelope giữ
/// nguyên — rồi đẩy token mới xuống native relay. Trả `true` → `ApiClient`
/// gửi lại request đúng một lần.
///
/// Single-flight: nhiều 401 đồng thời chỉ đăng ký lại một lần. Thất bại thì
/// nghỉ [failureCooldown] trước khi thử lại (tránh vòng lặp) và báo người dùng
/// một lần.
class DeviceSessionRecovery {
  DeviceSessionRecovery({
    required DeviceApiService deviceApi,
    required DeviceStorageService storage,
    RelayChannelBridge? relayBridge,
    DateTime Function()? clock,
    void Function(String message)? notifyFailure,
  }) : _deviceApi = deviceApi,
       _storage = storage,
       _relayBridge = relayBridge,
       _now = clock ?? DateTime.now,
       _notifyFailure = notifyFailure ?? ((message) => ToastUtils.showError(message));

  static const Duration failureCooldown = Duration(seconds: 30);

  final DeviceApiService _deviceApi;
  final DeviceStorageService _storage;
  final RelayChannelBridge? _relayBridge;
  final DateTime Function() _now;
  final void Function(String message) _notifyFailure;

  Future<bool>? _inFlight;
  DateTime? _lastFailureAt;

  Future<bool> call() {
    final running = _inFlight;
    if (running != null) return running;
    final lastFailure = _lastFailureAt;
    if (lastFailure != null && _now().difference(lastFailure) < failureCooldown) {
      return Future.value(false);
    }
    final attempt = _recover().whenComplete(() => _inFlight = null);
    _inFlight = attempt;
    return attempt;
  }

  Future<bool> _recover() async {
    try {
      // Chưa từng đăng ký → không phải phiên hết hạn; Splash lo việc đăng ký.
      final token = await _storage.getDeviceToken();
      final deviceId = await _storage.getDeviceId();
      if (token == null || token.isEmpty || deviceId == null || deviceId.isEmpty) return false;

      final deviceName = await _storage.getDeviceName();
      await _deviceApi.registerDevice(
        deviceName: (deviceName == null || deviceName.isEmpty) ? AppL10n.current.splashDefaultDeviceName : deviceName,
        platform: defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
      );
      final fresh = await _storage.getDeviceToken();
      if (fresh == null || fresh.isEmpty) throw StateError('register returned no token');
      await _relayBridge?.setCredentials(deviceToken: fresh, apiBaseUrl: await _storage.getServerUrl());

      _lastFailureAt = null;
      AppLogger.i('DeviceSessionRecovery', 'Re-registered $deviceId after a 401');
      return true;
    } catch (e, stack) {
      _lastFailureAt = _now();
      AppLogger.w('DeviceSessionRecovery', 'Re-registration after 401 failed', e, stack);
      _notifyFailure(AppL10n.current.sessionRecoveryFailed);
      return false;
    }
  }
}
