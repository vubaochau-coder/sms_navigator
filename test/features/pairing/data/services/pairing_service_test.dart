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
import 'package:sms_navigator/features/sender/data/services/native_relay_service.dart';

class _FakeNativeRelayService implements NativeRelayService {
  Map<String, dynamic>? lastConfig;

  @override
  Future<Map<String, dynamic>> getRelayConfig() async => lastConfig ?? {};

  @override
  Future<bool> setRelayConfig({
    bool? isRelayEnabled,
    String? relayMode,
    List<String>? senderWhitelist,
    String? pairId,
    String? sharedSecretBase64,
    String? relayUrl,
    String? deviceToken,
    String? deviceId,
  }) async {
    lastConfig = {
      'isRelayEnabled': isRelayEnabled,
      'relayMode': relayMode,
      'senderWhitelist': senderWhitelist,
      'pairId': pairId,
      'sharedSecretBase64': sharedSecretBase64,
      'relayUrl': relayUrl,
      'deviceToken': deviceToken,
      'deviceId': deviceId,
    };
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

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('generateSenderPairing', () {
    test('generates a 256-bit random secret with 10 minute TTL', () async {
      final service = await _buildService();

      final payload = await service.generateSenderPairing();

      expect(payload.code, '');
      expect(payload.pairId, startsWith('pair_'));
      expect(payload.expiresAt - payload.createdAt, 10 * 60 * 1000);
      final secretBytes = base64Decode(payload.sharedSecretBase64);
      expect(secretBytes.length, 32);
    });

    test('generates unique secrets per session', () async {
      final service = await _buildService();

      final first = await service.generateSenderPairing();
      final second = await service.generateSenderPairing();

      expect(first.sharedSecretBase64, isNot(second.sharedSecretBase64));
    });

    test('calls /pair/init on server and throws ApiException when init fails', () async {
      final fakeApi = _FakeApiClient()..shouldThrow = true;
      final service = await _buildService(apiClient: fakeApi);

      expect(
        () => service.generateSenderPairing(),
        throwsA(isA<ApiException>()),
      );
    });

    test('calls /pair/init and succeeds when server returns success: true and pair_id', () async {
      final fakeApi = _FakeApiClient()
        ..postResponse = {'success': true, 'pair_id': 'pair_server_123'};
      final service = await _buildService(apiClient: fakeApi);

      final payload = await service.generateSenderPairing();
      expect(payload.pairId, startsWith('pair_'));
      expect(fakeApi.lastPostPath, '/api/v1/pair/init');
    });
  });

  group('confirmReceiverPairingFromQr', () {
    test('omits fcm_token in body when FCM token is null or empty', () async {
      final fakeApi = _FakeApiClient()..postResponse = {'success': true};
      final fakeStorage = _FakeDeviceStorageService()..fcmToken = null;
      final service = await _buildService(apiClient: fakeApi, storageService: fakeStorage);

      final payload = PairingPayloadModel(
        pairId: 'pair_no_fcm',
        sharedSecretBase64: 'SECRET',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        expiresAt: DateTime.now().millisecondsSinceEpoch + 60000,
      );

      final ok = await service.confirmReceiverPairingFromQr(payload.toQrData());

      expect(ok, isTrue);
      expect(fakeApi.lastPostBody?.containsKey('fcm_token'), isFalse);
    });

    test('includes fcm_token in body when FCM token is available', () async {
      final fakeApi = _FakeApiClient()..postResponse = {'success': true};
      final fakeStorage = _FakeDeviceStorageService()..fcmToken = 'real_fcm_token_123';
      final service = await _buildService(apiClient: fakeApi, storageService: fakeStorage);

      final payload = PairingPayloadModel(
        pairId: 'pair_with_fcm',
        sharedSecretBase64: 'SECRET',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        expiresAt: DateTime.now().millisecondsSinceEpoch + 60000,
      );

      final ok = await service.confirmReceiverPairingFromQr(payload.toQrData());

      expect(ok, isTrue);
      expect(fakeApi.lastPostBody?['fcm_token'], 'real_fcm_token_123');
    });

    test('throws ApiException and does not store credentials when server confirm fails', () async {
      final fakeApi = _FakeApiClient()..shouldThrow = true;
      final service = await _buildService(apiClient: fakeApi);

      final payload = PairingPayloadModel(
        pairId: 'pair_fail_server',
        sharedSecretBase64: 'SECRET_FAIL',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        expiresAt: DateTime.now().millisecondsSinceEpoch + 60000,
      );

      await expectLater(
        service.confirmReceiverPairingFromQr(payload.toQrData()),
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

      final payload = PairingPayloadModel(
        pairId: 'pair_success_false',
        sharedSecretBase64: 'SECRET_SF',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        expiresAt: DateTime.now().millisecondsSinceEpoch + 60000,
      );

      await expectLater(
        service.confirmReceiverPairingFromQr(payload.toQrData()),
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
    test('stores pairId and shared secret for a valid QR payload', () async {
      final service = await _buildService();
      final payload = PairingPayloadModel(
        pairId: 'pair_valid_1234',
        sharedSecretBase64: 'VALID_SECRET',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        expiresAt: DateTime.now().millisecondsSinceEpoch + 60000,
      );

      final ok = await service.confirmReceiverPairingFromQr(payload.toQrData());

      expect(ok, isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(StorageKeys.receiverPairId), 'pair_valid_1234');
      expect(prefs.getString(StorageKeys.receiverSharedSecret), 'VALID_SECRET');
    });

    test('rejects an expired QR payload with a typed error', () async {
      final service = await _buildService();
      final payload = PairingPayloadModel(
        pairId: 'pair_expired',
        sharedSecretBase64: 'EXPIRED_SECRET',
        createdAt: DateTime.now().millisecondsSinceEpoch - 120000,
        expiresAt: DateTime.now().millisecondsSinceEpoch - 60000,
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

    test('rejects malformed QR data with a typed error', () async {
      final service = await _buildService();

      await expectLater(
        service.confirmReceiverPairingFromQr('garbage'),
        throwsA(isA<ApiException>()),
      );
      await expectLater(
        service.confirmReceiverPairingFromQr('{"exp":123}'),
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
      final service = await _buildService();
      final payload = PairingPayloadModel(
        pairId: 'pair_via_alias',
        sharedSecretBase64: 'ALIAS_SECRET',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        expiresAt: DateTime.now().millisecondsSinceEpoch + 60000,
      );

      final ok = await service.confirmReceiverPairing(payload.toQrData());

      expect(ok, isTrue);
    });
  });

  group('getReceiverPairing / clearReceiverPairing', () {
    test('returns null before pairing and payload after pairing', () async {
      final service = await _buildService();

      expect(await service.getReceiverPairing(), isNull);

      final payload = PairingPayloadModel(
        pairId: 'pair_status_check',
        sharedSecretBase64: 'STATUS_SECRET',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        expiresAt: DateTime.now().millisecondsSinceEpoch + 60000,
      );
      await service.confirmReceiverPairingFromQr(payload.toQrData());

      final stored = await service.getReceiverPairing();
      expect(stored, isNotNull);
      expect(stored!.pairId, 'pair_status_check');
      expect(stored.sharedSecretBase64, 'STATUS_SECRET');
    });

    test('clearReceiverPairing removes stored pairing data', () async {
      final service = await _buildService();
      final payload = PairingPayloadModel(
        pairId: 'pair_to_clear',
        sharedSecretBase64: 'CLEAR_SECRET',
        createdAt: DateTime.now().millisecondsSinceEpoch,
        expiresAt: DateTime.now().millisecondsSinceEpoch + 60000,
      );
      await service.confirmReceiverPairingFromQr(payload.toQrData());

      final cleared = await service.clearReceiverPairing();

      expect(cleared, isTrue);
      expect(await service.getReceiverPairing(), isNull);
    });
  });
}
