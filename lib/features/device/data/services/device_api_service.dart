import 'dart:math';

import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/services/device_storage_service.dart';

/// Service đăng ký thiết bị & đồng bộ FCM token với server.
abstract class DeviceApiService {
  /// Đăng ký thiết bị mới (hoặc làm mới đăng ký), lưu device_id/device_token
  /// trả về từ server vào [DeviceStorageService].
  Future<Map<String, dynamic>> registerDevice({
    String? deviceName,
    String? platform,
  });

  /// Cập nhật FCM token lên server để đẩy thông báo OTP.
  Future<void> updateFcmToken(String fcmToken);
}

class DeviceApiServiceImpl implements DeviceApiService {
  DeviceApiServiceImpl({required this.apiClient, required this.storageService});

  final ApiClient apiClient;
  final DeviceStorageService storageService;

  static const String _registerPath = ApiEndpoints.registerDevice;
  static const String _fcmTokenPath = ApiEndpoints.updateFcmToken;

  @override
  Future<Map<String, dynamic>> registerDevice({
    String? deviceName,
    String? platform,
  }) async {
    final existingId = await storageService.getDeviceId();
    final deviceId = existingId ?? _generateDeviceId();

    final body = <String, dynamic>{
      'device_id': deviceId,
      'device_name': deviceName,
      'platform': platform,
    }..removeWhere((_, v) => v == null);

    final data = await apiClient.post(_registerPath, body: body);
    final payload = _asMap(data);

    final serverDeviceId = payload['device_id']?.toString() ?? deviceId;
    await storageService.saveDeviceId(serverDeviceId);

    final deviceToken = (payload['device_token'] ?? payload['token'])
        ?.toString();
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

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return <String, dynamic>{};
  }

  String _generateDeviceId() {
    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch.toRadixString(36);
    final suffix = List.generate(8, (_) {
      return random.nextInt(16).toRadixString(16);
    }).join();
    return 'dev_${timestamp}_$suffix';
  }
}
