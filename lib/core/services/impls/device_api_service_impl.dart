import 'dart:math';

import 'package:dio/dio.dart';

import '../../constants/api_endpoints.dart';
import '../../errors/app_exceptions.dart';
import '../../network/api_client.dart';
import '../../utils/data_converter.dart';
import '../device_api_service.dart';
import '../device_storage_service.dart';

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
  static const String _updateNamePath = ApiEndpoints.updateDeviceNameV2;
  static const String _getDeviceMePath = ApiEndpoints.getDeviceMeV2;

  @override
  Future<Map<String, dynamic>> registerDevice({
    required String deviceName,
    required String platform,
    CancelToken? cancelToken,
  }) async {
    final publicKey = await publicKeyProvider();
    if (publicKey.isEmpty) {
      throw StateError('Chưa có identity key — không thể đăng ký thiết bị.');
    }

    final existingId = await storageService.getDeviceId();
    final deviceId = (_isValidUuid(existingId) ? existingId : null) ?? _generateUuidV4();

    final body = <String, dynamic>{
      'device_id': deviceId,
      'device_name': deviceName,
      'platform': platform,
      'public_key': publicKey,
      'fcm_token': await storageService.getFcmToken(),
    }..removeWhere((_, v) => v == null);

    final data = await apiClient.post(
      _registerPath,
      body: body,
      cancelToken: cancelToken,
    );
    final payload = DataConverter.cvToMap<String, dynamic>(data) ?? {};

    final serverDeviceId =
        DataConverter.cvToString(payload['device_id'], deviceId)!;
    await storageService.saveDeviceId(serverDeviceId);
    await storageService.saveDeviceName(deviceName);

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

  @override
  Future<void> updateDeviceName(String deviceName) async {
    await apiClient.put(
      _updateNamePath,
      body: <String, dynamic>{'device_name': deviceName},
    );
    await storageService.saveDeviceName(deviceName);
  }

  @override
  Future<bool> verifyDeviceToken({CancelToken? cancelToken}) async {
    final token = await storageService.getDeviceToken();
    if (token == null || token.isEmpty) {
      return false;
    }

    try {
      final data = await apiClient.get(
        _getDeviceMePath,
        cancelToken: cancelToken,
      );
      final payload = DataConverter.cvToMap<String, dynamic>(data);
      if (payload != null && payload['success'] == true) {
        final serverName = DataConverter.cvToString(payload['device_name']);
        if (serverName != null && serverName.isNotEmpty) {
          await storageService.saveDeviceName(serverName);
        }
        return true;
      }
      throw ApiException(
        'Phản hồi từ máy chủ không hợp lệ khi kiểm tra thiết bị.',
        statusCode: 200,
      );
    } on UnauthorizedException {
      return false;
    }
  }

  bool _isValidUuid(String? id) {
    if (id == null || id.length != 36) return false;
    if (id[8] != '-' || id[13] != '-' || id[18] != '-' || id[23] != '-') return false;
    for (var i = 0; i < 36; i++) {
      if (i == 8 || i == 13 || i == 18 || i == 23) continue;
      final code = id.codeUnitAt(i);
      final isHex = (code >= 48 && code <= 57) ||
          (code >= 65 && code <= 70) ||
          (code >= 97 && code <= 102);
      if (!isHex) return false;
    }
    return true;
  }

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
