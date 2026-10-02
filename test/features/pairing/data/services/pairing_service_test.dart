import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_navigator/core/errors/app_exceptions.dart';
import 'package:sms_navigator/core/network/api_client.dart';
import 'package:sms_navigator/core/services/device_storage_service.dart';
import 'package:sms_navigator/core/storage/local_storage_service.dart';
import 'package:sms_navigator/core/storage/storage_keys.dart';
import 'package:sms_navigator/features/pairing/data/models/pairing_payload_model.dart';
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
  Map<String, dynamic>? lastPostBody;
  String? lastPostPath;
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

Map<String, dynamic> _initResponse({
  String pairId = 'pair_server_123',
  String pairingKey = 'init_pairing_key_value',
  bool success = true,
}) {
  return {
    'success': success,
    'pair_id': pairId,
    'pairing_key': pairingKey,
    'expires_at': _serverExpiry(),
  };
}

String _serverExpiry() {
  return DateTime.now()
      .toUtc()
      .add(const Duration(minutes: 10))
      .toIso8601String();
}

Future<PairingServiceImpl> _buildService({
  ApiClient? apiClient,
  DeviceStorageService? storageService,
}) async {
  return PairingServiceImpl(
    nativeService: _FakeNativeRelayService(),
    localStorageService: await LocalStorageService.create(),
    apiClient: apiClient,
    deviceStorageService: storageService,
  );
}

PairingPayloadModel _receiverPayload({
  String pairingKey = 'valid_pairing_key_value',
  String secret = 'SECRET',
  int? expiresAt,
}) {
  final now = DateTime.now().millisecondsSinceEpoch;
  return PairingPayloadModel(
    pairId: '',
    pairingKey: pairingKey,
    sharedSecretBase64: secret,
    createdAt: now,
    expiresAt: expiresAt ?? now + 60000,
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('generateSenderPairing', () {
    test('requires the server: throws when no ApiClient is configured', () async {
      final service = await _buildService();

      await expectLater(
        service.generateSenderPairing(),
        throwsA(isA<ApiException>()),
      );
    });

    test('uses server-issued pair_id/pairing_key and generates a 256-bit secret', () async {
      final fakeApi = _FakeApiClient()..postResponse = _initResponse();
      final service = await _buildService(apiClient: fakeApi);

      final payload = await service.generateSenderPairing();

      expect(payload.pairId, 'pair_server_123');
      expect(payload.pairingKey, 'init_pairing_key_value');
      final secretBytes = base64Decode(payload.sharedSecretBase64);
      expect(secretBytes.length, 32);
      // TTL lấy từ expires_at do server trả về (ISO 8601)
      final serverExpiryMs = DateTime.parse(_serverExpiry()).toUtc().millisecondsSinceEpoch;
      expect((payload.expiresAt - serverExpiryMs).abs(), lessThan(1000));
      expect(fakeApi.lastPostPath, '/api/v1/pair/init');
      // Giao thức mới: client không còn tự đưa pair_id lên /init
      expect(fakeApi.lastPostBody, isEmpty);
    });

    test('generates unique secrets per session', () async {
      final fakeApi = _FakeApiClient()..postResponse = _initResponse();
      final first = await _buildService(apiClient: fakeApi);
      final second = await _buildService(apiClient: fakeApi);

      final firstPayload = await first.generateSenderPairing();
      final secondPayload = await second.generateSenderPairing();

      expect(firstPayload.sharedSecretBase64, isNot(secondPayload.sharedSecretBase64));
    });

    test('throws ApiException when server init fails', () async {
      final fakeApi = _FakeApiClient()..shouldThrow = true;
      final service = await _buildService(apiClient: fakeApi);

      expect(
        () => service.generateSenderPairing(),
        throwsA(isA<ApiException>()),
      );
    });

    test('throws ApiException when server omits pairing_key', () async {
      final fakeApi = _FakeApiClient()
        ..postResponse = {'success': true, 'pair_id': 'pair_no_key'};
      final service = await _buildService(apiClient: fakeApi);

      await expectLater(
        service.generateSenderPairing(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('confirmReceiverPairingFromQr', () {
    test('sends pairing_key and omits pair_id from the confirm body', () async {
      final fakeApi = _FakeApiClient()
        ..postResponse = {'success': true, 'pair_id': 'pair_confirmed_1'};
      final fakeStorage = _FakeDeviceStorageService()..fcmToken = null;
      final service = await _buildService(apiClient: fakeApi, storageService: fakeStorage);

      final ok = await service.confirmReceiverPairingFromQr(_receiverPayload().toQrData());

      expect(ok, isTrue);
      expect(fakeApi.lastPostBody?['pairing_key'], 'valid_pairing_key_value');
      expect(fakeApi.lastPostBody?.containsKey('pair_id'), isFalse);
      expect(fakeApi.lastPostBody?.containsKey('fcm_token'), isFalse);
    });

    test('stores the SERVER-issued pair_id and shared secret after confirm', () async {
      final fakeApi = _FakeApiClient()
        ..postResponse = {'success': true, 'pair_id': 'pair_from_server'};
      final service = await _buildService(apiClient: fakeApi);

      final ok = await service.confirmReceiverPairingFromQr(_receiverPayload().toQrData());

      expect(ok, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageKeys.receiverPairId), 'pair_from_server');
      expect(prefs.getString(StorageKeys.receiverSharedSecret), 'SECRET');
    });

    test('includes fcm_token in body when FCM token is available', () async {
      final fakeApi = _FakeApiClient()
        ..postResponse = {'success': true, 'pair_id': 'pair_with_fcm'};
      final fakeStorage = _FakeDeviceStorageService()..fcmToken = 'real_fcm_token_123';
      final service = await _buildService(apiClient: fakeApi, storageService: fakeStorage);

      final ok = await service.confirmReceiverPairingFromQr(_receiverPayload().toQrData());

      expect(ok, isTrue);
      expect(fakeApi.lastPostBody?['fcm_token'], 'real_fcm_token_123');
    });

    test('throws ApiException and does not store credentials when server confirm fails', () async {
      final fakeApi = _FakeApiClient()..shouldThrow = true;
      final service = await _buildService(apiClient: fakeApi);

      await expectLater(
        service.confirmReceiverPairingFromQr(_receiverPayload().toQrData()),
        throwsA(isA<ApiException>()),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageKeys.receiverPairId), isNull);
      expect(prefs.getString(StorageKeys.receiverSharedSecret), isNull);
    });

    test('throws when server responds 200 with success: false', () async {
      final fakeApi = _FakeApiClient()
        ..postResponse = {'success': false, 'message': 'Pair already confirmed'};
      final service = await _buildService(apiClient: fakeApi);

      await expectLater(
        service.confirmReceiverPairingFromQr(_receiverPayload().toQrData()),
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
      final service = await _buildService();
      final now = DateTime.now().millisecondsSinceEpoch;
      final payload = _receiverPayload(
        secret: 'EXPIRED_SECRET',
        expiresAt: now - 60000,
      );

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

    test('rejects malformed and legacy v1 QR data with a typed error', () async {
      final service = await _buildService();

      await expectLater(
        service.confirmReceiverPairingFromQr('garbage'),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        service.confirmReceiverPairingFromQr('{"exp":123}'),
        throwsA(isA<ApiException>()),
      );
      // Giao thức v1 đã ngừng hoạt động
      const legacy =
          '{"v":1,"pairId":"pair_legacy","secret":"LEGACY_SECRET","exp":9999999999999}';
      await expectLater(
        service.confirmReceiverPairingFromQr(legacy),
        throwsA(isA<ApiException>()),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageKeys.receiverPairId), isNull);
      expect(prefs.getString(StorageKeys.receiverSharedSecret), isNull);
    });
  });

  group('confirmReceiverPairing (legacy alias)', () {
    test('rejects the removed 6-digit OTP code mechanism with a typed error', () async {
      final service = await _buildService();

      await expectLater(
        service.confirmReceiverPairing('123456'),
        throwsA(isA<ApiException>()),
      );
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageKeys.receiverPairId), isNull);
    });

    test('still accepts a QR payload string', () async {
      final fakeApi = _FakeApiClient()
        ..postResponse = {'success': true, 'pair_id': 'pair_via_alias'};
      final service = await _buildService(apiClient: fakeApi);

      final ok = await service.confirmReceiverPairing(_receiverPayload().toQrData());

      expect(ok, isTrue);
    });
  });

  group('getReceiverPairing / clearReceiverPairing', () {
    test('returns null before pairing and payload after pairing', () async {
      final fakeApi = _FakeApiClient()
        ..postResponse = {'success': true, 'pair_id': 'pair_status_check'};
      final service = await _buildService(apiClient: fakeApi);

      expect(await service.getReceiverPairing(), isNull);

      await service.confirmReceiverPairingFromQr(_receiverPayload().toQrData());

      final stored = await service.getReceiverPairing();
      expect(stored, isNotNull);
      expect(stored!.pairId, 'pair_status_check');
      expect(stored.sharedSecretBase64, 'SECRET');
      // pairing_key one-time không được giữ lại sau khi confirm
      expect(stored.pairingKey, isEmpty);
    });

    test('clearReceiverPairing removes stored pairing data', () async {
      final fakeApi = _FakeApiClient()
        ..postResponse = {'success': true, 'pair_id': 'pair_to_clear'};
      final service = await _buildService(apiClient: fakeApi);
      await service.confirmReceiverPairingFromQr(_receiverPayload().toQrData());

      final cleared = await service.clearReceiverPairing();

      expect(cleared, isTrue);
      expect(await service.getReceiverPairing(), isNull);
    });
  });
}
