import 'dart:math';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/device_storage_service.dart';
import '../../../../core/utils/data_converter.dart';

/// Provider public key X25519 của identity key (ChannelKeyStore đảm bảo đã
/// sinh trước khi register — SRD 3.1).
typedef PublicKeyProvider = Future<String> Function();

/// Service đăng ký thiết bị (API spec §3.1) & đồng bộ FCM token (§3.2).
abstract class DeviceApiService {
  /// `POST /api/v2/devices/register` — idempotent theo device_id, lưu
  /// device_id/device_token vào [DeviceStorageService].
  Future<Map<String, dynamic>> registerDevice({
    required String deviceName,
    required String platform,
  });

  /// `PUT /api/v2/devices/fcm-token`.
  Future<void> updateFcmToken(String fcmToken);
}

class DeviceApiServiceImpl implements DeviceApiService {
  DeviceApiServiceImpl({
    required this.apiClient,
    required this.storageService,
    required this.publicKeyProvider,
  });

  final ApiClient apiClient;
  final DeviceStorageService storageService;
  final PublicKeyProvider publicKeyProvider;

  static const String _registerPath = ApiEndpoints.registerDeviceV2;
  static const String _fcmTokenPath = ApiEndpoints.updateFcmTokenV2;

  @override
  Future<Map<String, dynamic>> registerDevice({
    required String deviceName,
    required String platform,
  }) async {
    final publicKey = await publicKeyProvider();
    if (publicKey.isEmpty) {
      throw StateError('Chưa có identity key — không thể đăng ký thiết bị.');
    }

    // SRD 8.2: reinstall = thiết bị mới. device_id được lưu theo lần cài;
    // sau reinstall storage bị xóa → device_id mới + identity key mới.
    final existingId = await storageService.getDeviceId();
    final deviceId = existingId ?? _generateUuidV4();

    final body = <String, dynamic>{
      'device_id': deviceId,
      'device_name': deviceName,
      'platform': platform,
      'public_key': publicKey,
      'fcm_token': await storageService.getFcmToken(),
    }..removeWhere((_, v) => v == null);

    final data = await apiClient.post(_registerPath, body: body);
    final payload = DataConverter.cvToMap<String, dynamic>(data) ?? {};

    final serverDeviceId =
        DataConverter.cvToString(payload['device_id'], deviceId)!;
    await storageService.saveDeviceId(serverDeviceId);

    final deviceToken = DataConverter.cvToString(payload['device_token']);
    if (deviceToken != null && deviceToken.isNotEmpty) {
      await storageService.saveDeviceToken(deviceToken);
    }

    return payload;
  }

  @override
  Future<void> updateFcmToken(String fcmToken) async {
    if (fcmToken.trim().isEmpty) {
      throw ArgumentError.value(fcmToken, 'fcmToken', 'FCM token rỗng.');
    }
    await apiClient.put(
      _fcmTokenPath,
      body: <String, dynamic>{'fcm_token': fcmToken.trim()},
    );
  }

  /// UUID v4 chuẩn (SRD: device_id là UUID v4 sinh client mỗi lần cài đặt).
  String _generateUuidV4() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0F) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3F) | 0x80; // variant 10xx
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
