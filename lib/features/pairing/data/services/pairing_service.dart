import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_navigator/features/sender/data/services/native_relay_service.dart';
import '../../../../core/network/api_client.dart';
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

  PairingServiceImpl({
    required this.nativeService,
    this.apiClient,
    this.deviceApiService,
    this.deviceStorageService,
  });

  static const String _keyReceiverPairId = 'receiver_pair_id';
  static const String _keyReceiverSharedSecret = 'receiver_shared_secret';

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
    try {
      if (deviceApiService != null) {
        await deviceApiService!.registerDevice();
      }
      if (apiClient != null) {
        await apiClient!.post(
          '/api/v1/pair/init',
          body: {'pair_id': payload.pairId},
        );
      }
    } catch (_) {}

    // Cập nhật cấu hình relay (kèm relayUrl, deviceToken, deviceId) cho Android native.
    final serverUrl =
        await deviceStorageService?.getServerUrl() ?? ApiClient.defaultBaseUrl;
    final relayUrl = '$serverUrl/api/v1/relay';
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
    try {
      final payload = PairingPayloadModel.fromQrData(qrData);
      if (payload.isExpired) return false;

      // Lấy FCM token hiện tại để đồng bộ nhận thông báo tức thì từ server
      final storedFcm = await deviceStorageService?.getFcmToken();
      final fcmToken = (storedFcm != null && storedFcm.isNotEmpty)
          ? storedFcm
          : 'fcm_token_${payload.pairId}_${DateTime.now().millisecondsSinceEpoch}';

      // Đăng ký thiết bị nhận với server nếu có kết nối.
      try {
        if (deviceApiService != null) {
          await deviceApiService!.registerDevice();
        }
        if (apiClient != null) {
          await apiClient!.post(
            '/api/v1/pair/confirm',
            body: {
              'pair_id': payload.pairId,
              'fcm_token': fcmToken,
            },
          );
        }
      } catch (_) {}

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyReceiverPairId, payload.pairId);
      await prefs.setString(_keyReceiverSharedSecret, payload.sharedSecretBase64);

      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> confirmReceiverPairing(String data) {
    return confirmReceiverPairingFromQr(data);
  }

  @override
  Future<PairingPayloadModel?> getReceiverPairing() async {
    final prefs = await SharedPreferences.getInstance();
    final pairId = prefs.getString(_keyReceiverPairId);
    final sharedSecret = prefs.getString(_keyReceiverSharedSecret);

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyReceiverPairId);
    await prefs.remove(_keyReceiverSharedSecret);
    return true;
  }
}
