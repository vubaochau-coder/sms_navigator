/// Provider public key X25519 của identity key (ChannelKeyStore đảm bảo đã
/// sinh trước khi register — SRD 3.1).
typedef PublicKeyProvider = Future<String> Function();

/// Service API thiết bị (BE: DeviceV2Controller, API spec §3).
abstract class DeviceApiService {
  /// `POST /api/v2/devices/register` — idempotent theo device_id, lưu
  /// device_id/device_token vào [DeviceStorageService].
  Future<Map<String, dynamic>> registerDevice({
    required String deviceName,
    required String platform,
  });

  /// `PUT /api/v2/devices/fcm-token` (§3.2).
  Future<void> updateFcmToken(String fcmToken);

  /// `PUT /api/v2/devices/name` (§3.3) — đổi tên thiết bị.
  Future<void> updateDeviceName(String deviceName);
}
