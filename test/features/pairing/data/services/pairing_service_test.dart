import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_navigator/core/errors/app_exceptions.dart';
import 'package:sms_navigator/core/network/api_client.dart';
import 'package:sms_navigator/core/services/device_storage_service.dart';
import 'package:sms_navigator/core/storage/local_storage_service.dart';
import 'package:sms_navigator/core/storage/storage_keys.dart';
import 'package:sms_navigator/core/utils/crypto_helper.dart';
import 'package:sms_navigator/features/pairing/data/models/pairing_payload_model.dart';
import 'package:sms_navigator/features/pairing/data/models/sender_link_status.dart';
import 'package:sms_navigator/features/pairing/data/services/pairing_service.dart';
import 'package:sms_navigator/features/sender/data/models/whitelist_config_model.dart';
import 'package:sms_navigator/features/sender/data/services/native_relay_service.dart';

class _FakeNativeRelayService implements NativeRelayService {
  Map<String, dynamic>? lastConfig;
  WhitelistConfigModel lastWhitelist = const WhitelistConfigModel();

  @override
  Future<Map<String, dynamic>> getRelayConfig() async => lastConfig ?? {};

  @override
  Future<bool> setRelayConfig({
    bool? isRelayEnabled,
    String? pairId,
    String? sharedSecretBase64,
    String? relayUrl,
    String? deviceToken,
    String? deviceId,
  }) async {
    lastConfig = {
      'isRelayEnabled': isRelayEnabled,
      'pairId': pairId,
      'sharedSecretBase64': sharedSecretBase64,
      'relayUrl': relayUrl,
      'deviceToken': deviceToken,
      'deviceId': deviceId,
    };
    return true;
  }

  @override
  Future<WhitelistConfigModel> getWhitelist() async => lastWhitelist;

  @override
  Future<bool> setWhitelist(WhitelistConfigModel config) async {
    lastWhitelist = config;
    return true;
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentLogs() async => [];

  @override
  Future<bool> clearPairing() async {
    lastConfig = null;
    return true;
  }

  @override
  Future<bool> isBatteryOptimizationIgnored() async => true;

  @override
  Future<bool> requestIgnoreBatteryOptimization() async => true;

  @override
  Future<Map<String, dynamic>> getAggressiveRomInfo() async =>
      {'isAggressive': false, 'oem': null};

  @override
  Future<String?> getDeviceName() async => 'Test Device';

  @override
  Future<bool> openAutostartSettings() async => false;

  @override
  void setOnOtpDetectedListener(Function(String sender, String otp) listener) {}
}

class _FakeApiClient extends ApiClient {
  dynamic postResponse;
  dynamic getResponse;
  Map<String, dynamic>? lastPostBody;
  String? lastPostPath;
  String? lastGetPath;
  bool shouldThrow = false;

  @override
  Future<dynamic> post(
    String path, {
    Object? body,
    CancelToken? cancelToken,
  }) async {
    lastPostPath = path;
    lastPostBody = body as Map<String, dynamic>?;
    if (shouldThrow) {
      throw const ApiException('Server error');
    }
    return postResponse;
  }

  @override
  Future<dynamic> get(
    String path, {
    Map<String, String>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    lastGetPath = path;
    return getResponse;
  }
}

class _FakeDeviceStorageService implements DeviceStorageService {
  String? fcmToken;
  @override
  Future<String?> getFcmToken() async => fcmToken;
  @override
  Future<String?> getDeviceId() async => 'test_device_id';
  @override
  Future<String?> getDeviceToken() async => 'test_token';
  @override
  Future<String?> getServerUrl() async => null;
  @override
  Future<void> saveDeviceId(String deviceId) async {}
  @override
  Future<void> saveDeviceToken(String deviceToken) async {}
  @override
  Future<void> saveFcmToken(String token) async {
    fcmToken = token;
  }
  @override
  Future<void> saveServerUrl(String serverUrl) async {}
  @override
  Future<void> clearAll() async {}
}

String _serverExpiry() {
  return DateTime.now()
      .toUtc()
      .add(const Duration(minutes: 10))
      .toIso8601String();
}

Map<String, dynamic> _initResponse({
  String pairId = 'pair_server_123',
  String pairingKey = 'init_pairing_key_value',
}) {
  return {
    'success': true,
    'pair_id': pairId,
    'pairing_key': pairingKey,
    'expires_at': _serverExpiry(),
  };
}

/// Payload của Máy A với cặp khóa X25519 thật — dùng cho QR v3.
Future<PairingPayloadModel> _senderPayload({
  String pairId = 'pair_sender_001',
  String pairingKey = 'valid_pairing_key_value',
  int? expiresAt,
}) async {
  final keys = await CryptoHelper.generateX25519KeyPairBase64();
  final now = DateTime.now().millisecondsSinceEpoch;
  return PairingPayloadModel(
    pairId: pairId,
    pairingKey: pairingKey,
    senderPubkey: keys.publicKeyBase64,
    senderPrivateKeyBase64: keys.privateKeyBase64,
    createdAt: now,
    expiresAt: expiresAt ?? now + 60000,
  );
}

Future<PairingServiceImpl> _buildService({
  required _FakeNativeRelayService native,
  ApiClient? apiClient,
  DeviceStorageService? storageService,
}) async {
  return PairingServiceImpl(
    nativeService: native,
    localStorageService: await LocalStorageService.create(),
    apiClient: apiClient,
    deviceStorageService: storageService,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('generateSenderPairing (ECDH)', () {
    test('requires the server: throws when no ApiClient is configured', () async {
      final service = await _buildService(native: _FakeNativeRelayService());

      await expectLater(
        service.generateSenderPairing(),
        throwsA(isA<ApiException>()),
      );
    });

    test('sends the X25519 public key to /init and stores the private key locally', () async {
      final native = _FakeNativeRelayService();
      final fakeApi = _FakeApiClient()..postResponse = _initResponse();
      final service = await _buildService(native: native, apiClient: fakeApi);

      final payload = await service.generateSenderPairing();

      expect(payload.pairId, 'pair_server_123');
      expect(payload.pairingKey, 'init_pairing_key_value');
      // Public key gửi lên server, private key KHÔNG
      expect(fakeApi.lastPostPath, '/api/v1/pair/init');
      final sentPubkey = fakeApi.lastPostBody?['sender_pubkey'] as String?;
      expect(sentPubkey, isNotNull);
      expect(base64Decode(sentPubkey!).length, 32);
      expect(base64Decode(payload.senderPrivateKeyBase64).length, 32);
      // QR v3: chỉ có k + a + e, KHÔNG còn secret
      final qr = jsonDecode(payload.toQrData()) as Map<String, dynamic>;
      expect(qr['v'], 3);
      expect(qr['k'], 'init_pairing_key_value');
      expect(qr['a'], sentPubkey);
      expect(qr.containsKey('s'), isFalse);
      // Shared secret chưa tồn tại cho tới khi link thành công
      expect(payload.sharedSecretBase64, isEmpty);
      // Relay chưa được kích hoạt khi chưa derive key
      expect(native.lastConfig, isNull);
    });

    test('throws ApiException when server init fails', () async {
      final fakeApi = _FakeApiClient()..shouldThrow = true;
      final service = await _buildService(
        native: _FakeNativeRelayService(),
        apiClient: fakeApi,
      );

      expect(
        () => service.generateSenderPairing(),
        throwsA(isA<ApiException>()),
      );
    });

    test('throws ApiException when server omits pairing_key', () async {
      final fakeApi = _FakeApiClient()
        ..postResponse = {'success': true, 'pair_id': 'pair_no_key'};
      final service = await _buildService(
        native: _FakeNativeRelayService(),
        apiClient: fakeApi,
      );

      await expectLater(
        service.generateSenderPairing(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('checkSenderPairingLink (sender-side ECDH)', () {
    test('returns waiting while the receiver has not confirmed yet', () async {
      final payload = await _senderPayload();
      final fakeApi = _FakeApiClient()
        ..getResponse = {'pair_id': payload.pairId, 'is_paired': false};
      final native = _FakeNativeRelayService();
      final service = await _buildService(native: native, apiClient: fakeApi);

      final status = await service.checkSenderPairingLink(payload);

      expect(status, SenderLinkStatus.waiting);
      expect(native.lastConfig, isNull);
    });

    test('derives the same secret as the receiver and activates relay on link', () async {
      // Chuẩn bị 2 bên: Máy A (payload) + Máy B (cặp khóa receiver)
      final payload = await _senderPayload();
      final receiverKeys = await CryptoHelper.generateX25519KeyPairBase64();
      final fakeApi = _FakeApiClient()
        ..getResponse = {
          'pair_id': payload.pairId,
          'is_paired': true,
          'receiver_pubkey': receiverKeys.publicKeyBase64,
          'device_name': 'Máy B của Minh',
        };
      final native = _FakeNativeRelayService();
      final service = await _buildService(native: native, apiClient: fakeApi);

      final status = await service.checkSenderPairingLink(payload);

      expect(status.linked, isTrue);
      expect(status.receiverDeviceName, 'Máy B của Minh');
      // Derive từ phía Máy B (private B + public A) phải ra CÙNG key
      final receiverSecret = await CryptoHelper.derivePairingSecretBase64(
        privateKeyBase64: receiverKeys.privateKeyBase64,
        remotePublicKeyBase64: payload.senderPubkey,
        salt: payload.pairId,
      );
      expect(native.lastConfig?['pairId'], payload.pairId);
      expect(native.lastConfig?['sharedSecretBase64'], receiverSecret);
      expect(base64Decode(receiverSecret).length, 32);
      expect(fakeApi.lastGetPath, '/api/v1/pair/status/${payload.pairId}');
    });

    test('does nothing without a sender private key (receiver payloads)', () async {
      final payload = await _senderPayload();
      final blank = payload.copyWith();
      final noPrivKey = PairingPayloadModel(
        pairId: blank.pairId,
        pairingKey: blank.pairingKey,
        senderPubkey: blank.senderPubkey,
        createdAt: blank.createdAt,
        expiresAt: blank.expiresAt,
      );
      final native = _FakeNativeRelayService();
      final service = await _buildService(native: native);

      final status = await service.checkSenderPairingLink(noPrivKey);

      expect(status, SenderLinkStatus.waiting);
      expect(native.lastConfig, isNull);
    });
  });

  group('confirmReceiverPairingFromQr (receiver-side ECDH)', () {
    test('sends pairing_key + receiver_pubkey, derives secret and stores server pair_id', () async {
      final senderPayload = await _senderPayload();
      final fakeApi = _FakeApiClient()
        ..postResponse = {
          'success': true,
          'pair_id': 'pair_from_server',
          'sender_pubkey': senderPayload.senderPubkey,
        };
      final fakeStorage = _FakeDeviceStorageService()..fcmToken = null;
      final native = _FakeNativeRelayService();
      final service = await _buildService(
        native: native,
        apiClient: fakeApi,
        storageService: fakeStorage,
      );

      final ok = await service.confirmReceiverPairingFromQr(
        senderPayload.toQrData(),
      );

      expect(ok, isTrue);
      expect(fakeApi.lastPostBody?['pairing_key'], senderPayload.pairingKey);
      final sentReceiverPubkey =
          fakeApi.lastPostBody?['receiver_pubkey'] as String?;
      expect(base64Decode(sentReceiverPubkey!).length, 32);
      expect(fakeApi.lastPostBody?.containsKey('pair_id'), isFalse);
      expect(fakeApi.lastPostBody?.containsKey('fcm_token'), isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageKeys.receiverPairId), 'pair_from_server');
      final storedSecret =
          prefs.getString(StorageKeys.receiverSharedSecret) ?? '';
      // Secret được derive nội bộ từ ECDH (priv B sinh trong service + pub A
      // từ QR): chỉ kiểm chứng cấu trúc 32 byte — tính hai bên derive cùng
      // key đã được chứng minh ở test checkSenderPairingLink và crypto test.
      expect(storedSecret, isNotEmpty);
      expect(base64Decode(storedSecret).length, 32);
    });

    test('rejects a server sender_pubkey that does not match the QR (anti key-swap)', () async {
      final senderPayload = await _senderPayload();
      const mismatchedPubkey = 'b2xkX3B1YmtleV9kb2VzX25vdF9tYXRjaF9xdXI=';
      final fakeApi = _FakeApiClient()
        ..postResponse = {
          'success': true,
          'pair_id': 'pair_swap_attempt',
          'sender_pubkey': mismatchedPubkey,
        };
      final service = await _buildService(
        native: _FakeNativeRelayService(),
        apiClient: fakeApi,
      );

      await expectLater(
        service.confirmReceiverPairingFromQr(senderPayload.toQrData()),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 422)
              .having((e) => e.message, 'message', contains('không khớp')),
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageKeys.receiverPairId), isNull);
      expect(prefs.getString(StorageKeys.receiverSharedSecret), isNull);
    });

    test('throws ApiException and does not store credentials when server confirm fails', () async {
      final senderPayload = await _senderPayload();
      final fakeApi = _FakeApiClient()..shouldThrow = true;
      final service = await _buildService(
        native: _FakeNativeRelayService(),
        apiClient: fakeApi,
      );

      await expectLater(
        service.confirmReceiverPairingFromQr(senderPayload.toQrData()),
        throwsA(isA<ApiException>()),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageKeys.receiverPairId), isNull);
      expect(prefs.getString(StorageKeys.receiverSharedSecret), isNull);
    });

    test('throws when server responds 200 with success: false', () async {
      final senderPayload = await _senderPayload();
      final fakeApi = _FakeApiClient()
        ..postResponse = {'success': false, 'message': 'Pair already confirmed'};
      final service = await _buildService(
        native: _FakeNativeRelayService(),
        apiClient: fakeApi,
      );

      await expectLater(
        service.confirmReceiverPairingFromQr(senderPayload.toQrData()),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            contains('Pair already confirmed'),
          ),
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageKeys.receiverPairId), isNull);
    });

    test('rejects an expired QR payload with a typed error', () async {
      final service = await _buildService(native: _FakeNativeRelayService());
      final now = DateTime.now().millisecondsSinceEpoch;
      final payload = await _senderPayload(expiresAt: now - 60000);

      await expectLater(
        service.confirmReceiverPairingFromQr(payload.toQrData()),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 410)
              .having((e) => e.message, 'message', contains('hết hạn')),
        ),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageKeys.receiverPairId), isNull);
      expect(prefs.getString(StorageKeys.receiverSharedSecret), isNull);
    });

    test('rejects malformed and legacy QR data with a typed error', () async {
      final service = await _buildService(native: _FakeNativeRelayService());

      await expectLater(
        service.confirmReceiverPairingFromQr('garbage'),
        throwsA(isA<ApiException>()),
      );
      // Giao thức v1 và v2 đã ngừng hoạt động
      const legacy =
          '{"v":1,"pairId":"pair_legacy","secret":"LEGACY_SECRET","exp":9999999999999}';
      const v2 = '{"v":2,"k":"a9V_x8Qe2mZ1wKd5Tn7cRg","s":"SECRET","e":9999999999999}';
      await expectLater(
        service.confirmReceiverPairingFromQr(legacy),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        service.confirmReceiverPairingFromQr(v2),
        throwsA(isA<ApiException>()),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageKeys.receiverPairId), isNull);
      expect(prefs.getString(StorageKeys.receiverSharedSecret), isNull);
    });
  });

  group('confirmSenderPairing (relay activation)', () {
    test('skips relay activation when the payload has no derived secret', () async {
      final native = _FakeNativeRelayService();
      final service = await _buildService(native: native);
      final payload = await _senderPayload();

      final result = await service.confirmSenderPairing(payload);

      expect(result, isFalse);
      expect(native.lastConfig, isNull);
    });
  });

  group('confirmReceiverPairing (legacy alias)', () {
    test('rejects the removed 6-digit OTP code mechanism with a typed error', () async {
      final service = await _buildService(native: _FakeNativeRelayService());

      await expectLater(
        service.confirmReceiverPairing('123456'),
        throwsA(isA<ApiException>()),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageKeys.receiverPairId), isNull);
    });

    test('still accepts a QR payload string', () async {
      final senderPayload = await _senderPayload();
      final fakeApi = _FakeApiClient()
        ..postResponse = {
          'success': true,
          'pair_id': 'pair_via_alias',
          'sender_pubkey': senderPayload.senderPubkey,
        };
      final service = await _buildService(
        native: _FakeNativeRelayService(),
        apiClient: fakeApi,
      );

      final ok = await service.confirmReceiverPairing(senderPayload.toQrData());

      expect(ok, isTrue);
    });
  });

  group('getReceiverPairing / clearReceiverPairing', () {
    test('returns null before pairing and payload after pairing', () async {
      final senderPayload = await _senderPayload();
      final fakeApi = _FakeApiClient()
        ..postResponse = {
          'success': true,
          'pair_id': 'pair_status_check',
          'sender_pubkey': senderPayload.senderPubkey,
        };
      final service = await _buildService(
        native: _FakeNativeRelayService(),
        apiClient: fakeApi,
      );

      expect(await service.getReceiverPairing(), isNull);

      await service.confirmReceiverPairingFromQr(senderPayload.toQrData());

      final stored = await service.getReceiverPairing();
      expect(stored, isNotNull);
      expect(stored!.pairId, 'pair_status_check');
      expect(stored.sharedSecretBase64, isNotEmpty);
      // pairing_key one-time không được giữ lại sau khi confirm
      expect(stored.pairingKey, isEmpty);
    });

    test('clearReceiverPairing removes stored pairing data', () async {
      final senderPayload = await _senderPayload();
      final fakeApi = _FakeApiClient()
        ..postResponse = {
          'success': true,
          'pair_id': 'pair_to_clear',
          'sender_pubkey': senderPayload.senderPubkey,
        };
      final service = await _buildService(
        native: _FakeNativeRelayService(),
        apiClient: fakeApi,
      );
      await service.confirmReceiverPairingFromQr(senderPayload.toQrData());

      final cleared = await service.clearReceiverPairing();

      expect(cleared, isTrue);
      expect(await service.getReceiverPairing(), isNull);
    });
  });
}
