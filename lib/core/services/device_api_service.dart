import 'package:dio/dio.dart';

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
    CancelToken? cancelToken,
  });

  /// `PUT /api/v2/devices/fcm-token` (§3.2).
  Future<void> updateFcmToken(String fcmToken);

  /// `PUT /api/v2/devices/name` (§3.3) — đổi tên thiết bị.
  Future<void> updateDeviceName(String deviceName);

  /// `GET /api/v2/devices/me` (§3.4) — kiểm tra tính hợp lệ của device token.
  ///
  /// - Trả về `true` nếu token hợp lệ (200 OK).
  /// - Trả về `false` nếu token không hợp lệ hoặc đã bị hủy (401 UNAUTHORIZED).
  /// - Ném [NetworkException] / [ApiException] khi mất mạng hoặc lỗi máy chủ để chặn tiến trình.
  Future<bool> verifyDeviceToken({CancelToken? cancelToken});
}
