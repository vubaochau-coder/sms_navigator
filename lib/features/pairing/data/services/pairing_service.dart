import 'package:sms_navigator/features/sender/data/services/native_relay_service.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/utils/crypto_helper.dart';
import '../../../device/data/services/device_api_service.dart';
import '../../../../core/services/device_storage_service.dart';
import '../models/pairing_payload_model.dart';

abstract class PairingService {
  Future<PairingPayloadModel> generateSenderPairing();
  Future<bool> confirmSenderPairing(PairingPayloadModel payload);
  Future<bool> confirmReceiverPairingFromQr(String qrData);
  Future<bool> confirmReceiverPairing(String data);
  Future<PairingPayloadModel?> getReceiverPairing();
  Future<bool> clearReceiverPairing();
}

class PairingServiceImpl implements PairingService {
  final NativeRelayService nativeService;
  final ApiClient? apiClient;
  final DeviceApiService? deviceApiService;
  final DeviceStorageService? deviceStorageService;
  final LocalStorageService localStorageService;

  PairingServiceImpl({
    required this.nativeService,
    required this.localStorageService,
    this.apiClient,
    this.deviceApiService,
    this.deviceStorageService,
  });

  static const String _platformAndroid = 'android';

  Future<String?> _resolveDeviceName() async {
    try {
      return await nativeService.getDeviceName();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PairingPayloadModel> generateSenderPairing() async {
    final sharedSecretBase64 = CryptoHelper.generateSecretKeyBase64();
    final pairId =
        'pair_${DateTime.now().millisecondsSinceEpoch.toRadixString(16)}_${CryptoHelper.sha256Hash(sharedSecretBase64).substring(0, 8)}';
    final now = DateTime.now().millisecondsSinceEpoch;
    final expiresAt = now + (10 * 60 * 1000); // 10 minutes

    final payload = PairingPayloadModel(
      pairId: pairId,
      sharedSecretBase64: sharedSecretBase64,
      createdAt: now,
      expiresAt: expiresAt,
      code: '',
    );

    // Đăng ký thiết bị gửi với server trước khi mở phiên ghép đôi nếu có kết nối.
    if (deviceApiService != null) {
      await deviceApiService!.registerDevice(
        deviceName: await _resolveDeviceName(),
        platform: _platformAndroid,
      );
    }
    if (apiClient != null) {
      final response = await apiClient!.post(
        ApiEndpoints.initPair,
        body: {'pair_id': payload.pairId},
      );
      if (response is Map<String, dynamic>) {
        if (response['success'] != true || response['pair_id'] == null) {
          throw ApiException(
            response['message']?.toString() ?? 'Khởi tạo ghép đôi thất bại',
          );
        }
      }
    }

    // Cập nhật cấu hình relay (kèm relayUrl, deviceToken, deviceId) cho Android native.
    final serverUrl =
        await deviceStorageService?.getServerUrl() ?? ApiClient.defaultBaseUrl;
    final relayUrl = '$serverUrl${ApiEndpoints.relay}';
    final deviceToken = await deviceStorageService?.getDeviceToken();
    final deviceId = await deviceStorageService?.getDeviceId();

    await nativeService.setRelayConfig(
      isRelayEnabled: true,
      pairId: payload.pairId,
      sharedSecretBase64: payload.sharedSecretBase64,
      relayUrl: relayUrl,
      deviceToken: deviceToken,
      deviceId: deviceId,
    );

    return payload;
  }

  @override
  Future<bool> confirmSenderPairing(PairingPayloadModel payload) async {
    final deviceToken = await deviceStorageService?.getDeviceToken();
    final deviceId = await deviceStorageService?.getDeviceId();

    return await nativeService.setRelayConfig(
      isRelayEnabled: true,
      pairId: payload.pairId,
      sharedSecretBase64: payload.sharedSecretBase64,
      deviceToken: deviceToken,
      deviceId: deviceId,
    );
  }

  @override
  Future<bool> confirmReceiverPairingFromQr(String qrData) async {
    final PairingPayloadModel payload;
    try {
      payload = PairingPayloadModel.fromQrData(qrData);
    } on FormatException {
      throw const ApiException('Mã QR không đúng định dạng.');
    }

    if (payload.isExpired) {
      throw const ApiException(
        'Phiên ghép đôi đã hết hạn (QR chỉ hiệu lực trong 10 phút). Vui lòng tạo mã mới trên Máy A.',
        statusCode: 410,
      );
    }

    // Lấy FCM token hiện tại để đồng bộ nhận thông báo tức thì từ server.
    // Nếu chưa có FCM token, tuyệt đối không bịa token giả mà để optional (không gửi field fcm_token).
    final storedFcm = await deviceStorageService?.getFcmToken();
    final fcmToken = (storedFcm != null && storedFcm.trim().isNotEmpty)
        ? storedFcm.trim()
        : null;

    // Đăng ký thiết bị nhận với server nếu có kết nối.
    if (deviceApiService != null) {
      await deviceApiService!.registerDevice(
        deviceName: await _resolveDeviceName(),
        platform: _platformAndroid,
      );
    }
    if (apiClient != null) {
      final deviceName = await _resolveDeviceName();
      final body = <String, dynamic>{
        'pair_id': payload.pairId,
        if (deviceName != null && deviceName.isNotEmpty) 'device_name': deviceName,
        'platform': _platformAndroid,
      };
      if (fcmToken != null) {
        body['fcm_token'] = fcmToken;
      }
      final response = await apiClient!.post(
        ApiEndpoints.confirmPair,
        body: body,
      );
      if (response is Map<String, dynamic> && response['success'] != true) {
        throw ApiException(
          response['message']?.toString() ?? 'Server từ chối xác nhận ghép đôi',
        );
      }
    }

    await localStorageService.setString(
      StorageKeys.receiverPairId,
      payload.pairId,
    );
    await localStorageService.setString(
      StorageKeys.receiverSharedSecret,
      payload.sharedSecretBase64,
    );

    return true;
  }

  @override
  Future<bool> confirmReceiverPairing(String data) {
    return confirmReceiverPairingFromQr(data);
  }

  @override
  Future<PairingPayloadModel?> getReceiverPairing() async {
    final pairId = localStorageService.getString(StorageKeys.receiverPairId);
    final sharedSecret = localStorageService.getString(
      StorageKeys.receiverSharedSecret,
    );

    if (pairId == null || sharedSecret == null) return null;

    return PairingPayloadModel(
      pairId: pairId,
      sharedSecretBase64: sharedSecret,
      createdAt: 0,
      expiresAt: 0,
    );
  }

  @override
  Future<bool> clearReceiverPairing() async {
    await localStorageService.remove(StorageKeys.receiverPairId);
    await localStorageService.remove(StorageKeys.receiverSharedSecret);
    return true;
  }
}
