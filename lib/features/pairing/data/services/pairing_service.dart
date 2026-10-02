import 'package:sms_navigator/features/sender/data/services/native_relay_service.dart';
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/errors/app_exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/storage/storage_keys.dart';
import '../../../../core/utils/crypto_helper.dart';
import '../../../../core/utils/data_converter.dart';
import '../../../device/data/services/device_api_service.dart';
import '../../../../core/services/device_storage_service.dart';
import '../models/pairing_payload_model.dart';
import '../models/sender_link_status.dart';

abstract class PairingService {
  Future<PairingPayloadModel> generateSenderPairing();
  Future<bool> confirmSenderPairing(PairingPayloadModel payload);
  Future<SenderLinkStatus> checkSenderPairingLink(PairingPayloadModel payload);
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

  /// Shared secret ECDH lưu trong secure storage (GĐ4.1), KHÔNG lưu
  /// shared_preferences. Cấu hình qua constructor để test dễ dàng.
  final SecureStorageService? secureStorageService;

  PairingServiceImpl({
    required this.nativeService,
    required this.localStorageService,
    this.apiClient,
    this.deviceApiService,
    this.deviceStorageService,
    this.secureStorageService,
  });

  SecureStorageService get _secureStorage =>
      secureStorageService ?? SecureStorageServiceImpl();

  /// Đọc shared secret: ưu tiên secure storage; nếu trống thì migrate giá trị
  /// cũ từ shared_preferences (phiên bản trước GĐ4.1) một cách trong suốt.
  Future<String?> _readSharedSecret() async {
    final secret = await _secureStorage.read(StorageKeys.receiverSharedSecret);
    if (secret != null && secret.isNotEmpty) return secret;

    final legacy = localStorageService.getString(
      StorageKeys.receiverSharedSecret,
    );
    if (legacy != null && legacy.isNotEmpty) {
      await _secureStorage.write(StorageKeys.receiverSharedSecret, legacy);
      await localStorageService.remove(StorageKeys.receiverSharedSecret);
      return legacy;
    }
    return null;
  }

  Future<void> _writeSharedSecret(String secret) async {
    await _secureStorage.write(StorageKeys.receiverSharedSecret, secret);
    // Dọn bản plaintext cũ (nếu có) khỏi shared_preferences
    await localStorageService.remove(StorageKeys.receiverSharedSecret);
  }

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
    final api = apiClient;
    if (api == null) {
      throw const ApiException(
        'Chưa cấu hình kết nối máy chủ, không thể tạo phiên ghép đôi.',
      );
    }

    // Handshake ECDH: Máy A sinh cặp khóa X25519 một lần. Private key chỉ
    // tồn tại trong RAM; server chỉ nhận public key.
    final keys = await CryptoHelper.generateX25519KeyPairBase64();
    final now = DateTime.now().millisecondsSinceEpoch;

    // Máy chủ phát hành cả pairId lẫn one-time pairing_key.
    final response = await api.post(
      ApiEndpoints.initPair,
      body: {'sender_pubkey': keys.publicKeyBase64},
    );
    final map = DataConverter.cvToMap<String, dynamic>(response);
    final success = DataConverter.cvToBool(map?['success']) == true;
    final pairId = DataConverter.cvToString(map?['pair_id'], '')!;
    final pairingKey = DataConverter.cvToString(map?['pairing_key'], '')!;
    if (!success || pairId.isEmpty || pairingKey.isEmpty) {
      throw ApiException(
        DataConverter.cvToString(
          map?['message'],
          'Khởi tạo ghép đôi thất bại',
        )!,
      );
    }
    final expiresAt =
        _parseServerExpiryMs(map?['expires_at']) ?? now + (10 * 60 * 1000);

    // Shared secret chưa tồn tại ở giai đoạn này: nó chỉ được derive sau khi
    // Máy B confirm (xem [checkSenderPairingLink]). Do đó KHÔNG bật relay ngay.
    return PairingPayloadModel(
      pairId: pairId,
      pairingKey: pairingKey,
      senderPubkey: keys.publicKeyBase64,
      senderPrivateKeyBase64: keys.privateKeyBase64,
      createdAt: now,
      expiresAt: expiresAt,
    );
  }

  /// `expires_at` từ server là chuỗi ISO 8601 UTC.
  int? _parseServerExpiryMs(Object? value) {
    final iso = DataConverter.cvToString(value, '');
    if (iso == null || iso.isEmpty) return null;
    return DateTime.tryParse(iso)?.toUtc().millisecondsSinceEpoch;
  }

  @override
  Future<bool> confirmSenderPairing(PairingPayloadModel payload) async {
    // Với ECDH, relay chỉ được bật khi đã derive được shared secret
    // (sau khi link với Máy B). Payload chưa link thì bỏ qua.
    if (payload.sharedSecretBase64.isEmpty) return false;
    return _applySenderRelayConfig(payload);
  }

  Future<bool> _applySenderRelayConfig(PairingPayloadModel payload) async {
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
  Future<SenderLinkStatus> checkSenderPairingLink(
    PairingPayloadModel payload,
  ) async {
    final api = apiClient;
    if (api == null) return SenderLinkStatus.waiting;
    if (payload.pairId.isEmpty || payload.senderPrivateKeyBase64.isEmpty) {
      return SenderLinkStatus.waiting;
    }

    final response = await api.get(
      '${ApiEndpoints.pairStatus}/${payload.pairId}',
    );
    final map = DataConverter.cvToMap<String, dynamic>(response);
    if (map == null) return SenderLinkStatus.waiting;

    final isPaired = DataConverter.cvToBool(map['is_paired']) == true;
    final receiverPubkey = DataConverter.cvToString(
      map['receiver_pubkey'],
      '',
    )!;
    if (!isPaired || receiverPubkey.isEmpty) return SenderLinkStatus.waiting;

    // Máy B đã confirm: derive shared secret từ ECDH rồi kích hoạt relay.
    final derivedSecret = await CryptoHelper.derivePairingSecretBase64(
      privateKeyBase64: payload.senderPrivateKeyBase64,
      remotePublicKeyBase64: receiverPubkey,
      salt: payload.pairId,
    );
    final linked = payload.copyWith(sharedSecretBase64: derivedSecret);
    final applied = await _applySenderRelayConfig(linked);
    if (!applied) return SenderLinkStatus.waiting;

    return SenderLinkStatus(
      linked: true,
      receiverDeviceName: DataConverter.cvToString(map['device_name']),
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

    final api = apiClient;
    if (api == null) {
      throw const ApiException(
        'Chưa cấu hình kết nối máy chủ, không thể xác nhận ghép đôi.',
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

    // Sinh cặp khóa X25519 của Máy B. Private key không rời khỏi thiết bị.
    final keys = await CryptoHelper.generateX25519KeyPairBase64();

    final deviceName = await _resolveDeviceName();
    final body = <String, dynamic>{
      // Bằng chứng sở hữu QR: server chỉ xác nhận khi pairing_key khớp
      // phiên còn hiệu lực và chưa được sử dụng (one-time).
      'pairing_key': payload.pairingKey,
      // Public key của Máy B cho handshake ECDH — server chỉ forward,
      // không thể derive shared secret từ nó.
      'receiver_pubkey': keys.publicKeyBase64,
      if (deviceName != null && deviceName.isNotEmpty)
        'device_name': deviceName,
      'platform': _platformAndroid,
    };
    if (fcmToken != null) {
      body['fcm_token'] = fcmToken;
    }

    final response = await api.post(ApiEndpoints.confirmPair, body: body);
    final map = DataConverter.cvToMap<String, dynamic>(response);
    if (map == null || DataConverter.cvToBool(map['success']) != true) {
      throw ApiException(
        DataConverter.cvToString(
          map?['message'],
          'Server từ chối xác nhận ghép đôi',
        )!,
      );
    }

    // pairId do máy chủ phát hành và chỉ được biết sau khi confirm thành công.
    final confirmedPairId = DataConverter.cvToString(map['pair_id'], '')!;
    if (confirmedPairId.isEmpty) {
      throw const ApiException('Máy chủ không trả về mã phiên ghép đôi.');
    }

    // Chống server key-swap: public key của Máy A phải khớp đúng giá trị
    // đọc từ QR (kênh tin cậy vật lý), nếu không từ chối ghép đôi.
    final serverSenderPubkey = DataConverter.cvToString(
      map['sender_pubkey'],
      '',
    )!;
    if (serverSenderPubkey.isNotEmpty &&
        serverSenderPubkey != payload.senderPubkey) {
      throw const ApiException(
        'Khóa phiên ghép đôi không khớp mã QR. Vui lòng quét lại mã mới.',
        statusCode: 422,
      );
    }

    // Derive shared secret bằng ECDH với public key của Máy A lấy TỪ QR
    // (kênh tin cậy), không dùng giá trị do server trả về.
    final derivedSecret = await CryptoHelper.derivePairingSecretBase64(
      privateKeyBase64: keys.privateKeyBase64,
      remotePublicKeyBase64: payload.senderPubkey,
      salt: confirmedPairId,
    );

    await localStorageService.setString(
      StorageKeys.receiverPairId,
      confirmedPairId,
    );
    await _writeSharedSecret(derivedSecret);

    return true;
  }

  @override
  Future<bool> confirmReceiverPairing(String data) {
    return confirmReceiverPairingFromQr(data);
  }

  @override
  Future<PairingPayloadModel?> getReceiverPairing() async {
    final pairId = localStorageService.getString(StorageKeys.receiverPairId);
    final sharedSecret = await _readSharedSecret();

    if (pairId == null || sharedSecret == null) return null;

    // pairing_key không được lưu lại: nó đã được tiêu (one-time) lúc confirm.
    return PairingPayloadModel(
      pairId: pairId,
      pairingKey: '',
      sharedSecretBase64: sharedSecret,
      createdAt: 0,
      expiresAt: 0,
    );
  }

  @override
  Future<bool> clearReceiverPairing() async {
    await localStorageService.remove(StorageKeys.receiverPairId);
    await _secureStorage.delete(StorageKeys.receiverSharedSecret);
    await localStorageService.remove(StorageKeys.receiverSharedSecret);
    return true;
  }
}
