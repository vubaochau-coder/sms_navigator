import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/constants/api_endpoints.dart';
import 'package:sms_navigator/core/errors/app_exceptions.dart';
import 'package:sms_navigator/core/network/api_client.dart';
import 'package:sms_navigator/core/services/device_storage_service.dart';
import 'package:sms_navigator/core/services/impls/device_api_service_impl.dart';

class _FakeDeviceStorageService implements DeviceStorageService {
  String? deviceId;
  String? deviceName;
  String? deviceToken;
  String? fcmToken;
  String? serverUrl;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<String?> getDeviceId() async => deviceId;

  @override
  Future<void> saveDeviceId(String id) async => deviceId = id;

  @override
  Future<String?> getDeviceName() async => deviceName;

  @override
  Future<void> saveDeviceName(String name) async => deviceName = name;

  @override
  Future<String?> getDeviceToken() async => deviceToken;

  @override
  Future<void> saveDeviceToken(String token) async => deviceToken = token;

  @override
  Future<String?> getFcmToken() async => fcmToken;

  @override
  Future<void> saveFcmToken(String token) async => fcmToken = token;
}

class _FakeApiClient extends ApiClient {
  _FakeApiClient() : super(dio: Dio());

  Object? getResponse;
  Exception? getException;
  String? lastGetPath;

  Object? postResponse;
  Exception? postException;
  String? lastPostPath;
  dynamic lastPostBody;

  Object? putResponse;
  Exception? putException;
  String? lastPutPath;
  dynamic lastPutBody;

  @override
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
    lastGetPath = path;
    if (getException != null) throw getException!;
    return getResponse;
  }

  @override
  Future<dynamic> post(
    String path, {
    Object? body,
    CancelToken? cancelToken,
  }) async {
    lastPostPath = path;
    lastPostBody = body;
    if (postException != null) throw postException!;
    return postResponse;
  }

  @override
  Future<dynamic> put(
    String path, {
    Object? body,
    CancelToken? cancelToken,
  }) async {
    lastPutPath = path;
    lastPutBody = body;
    if (putException != null) throw putException!;
    return putResponse;
  }
}

void main() {
  late _FakeApiClient apiClient;
  late _FakeDeviceStorageService storage;
  late DeviceApiServiceImpl service;

  setUp(() {
    apiClient = _FakeApiClient();
    storage = _FakeDeviceStorageService();
    service = DeviceApiServiceImpl(
      apiClient: apiClient,
      storageService: storage,
      publicKeyProvider: () async => 'dummy_pub_key_base64',
    );
  });

  group('DeviceApiServiceImpl - verifyDeviceToken', () {
    test('returns false when no local token exists', () async {
      storage.deviceToken = null;

      final status = await service.verifyDeviceToken();

      expect(status, isFalse);
      expect(apiClient.lastGetPath, isNull);
    });

    test('returns true and syncs device name when API responds 200 with success: true', () async {
      storage.deviceToken = 'valid_bearer_token';
      apiClient.getResponse = {
        'success': true,
        'device_id': 'dev_123',
        'device_name': 'Pixel 9 Pro',
        'platform': 'android',
      };

      final status = await service.verifyDeviceToken();

      expect(status, isTrue);
      expect(apiClient.lastGetPath, ApiEndpoints.getDeviceMeV2);
      expect(storage.deviceName, 'Pixel 9 Pro');
    });

    test('returns false when server returns UnauthorizedException (401)', () async {
      storage.deviceToken = 'stale_bearer_token';
      apiClient.getException = const UnauthorizedException('Invalid or unknown device token');

      final status = await service.verifyDeviceToken();

      expect(status, isFalse);
      expect(apiClient.lastGetPath, ApiEndpoints.getDeviceMeV2);
    });

    test('rethrows NetworkException when server fails with NetworkException (blocking startup)', () async {
      storage.deviceToken = 'bearer_token';
      apiClient.getException = const NetworkException('Connection timeout');

      expect(
        () => service.verifyDeviceToken(),
        throwsA(isA<NetworkException>()),
      );
    });

    test('throws ApiException when server returns 200 with invalid payload (does not silently return false)', () async {
      storage.deviceToken = 'valid_bearer_token';
      apiClient.getResponse = {'success': false, 'error': 'SERVER_ERROR'};

      expect(
        () => service.verifyDeviceToken(),
        throwsA(isA<ApiException>()),
      );
    });
  });

  group('DeviceApiServiceImpl - registerDevice', () {
    test('registers successfully and persists id, name, and token', () async {
      apiClient.postResponse = {
        'success': true,
        'device_id': 'srv_dev_1',
        'device_token': 'new_token_123',
      };

      final result = await service.registerDevice(
        deviceName: 'Pixel 8',
        platform: 'android',
      );

      expect(result['device_id'], 'srv_dev_1');
      expect(storage.deviceId, 'srv_dev_1');
      expect(storage.deviceName, 'Pixel 8');
      expect(storage.deviceToken, 'new_token_123');
      expect(apiClient.lastPostPath, ApiEndpoints.registerDeviceV2);
    });

    test('generates new UUID v4 if existing storage deviceId is not a valid UUID', () async {
      storage.deviceId = 'legacy_non_uuid_123';
      apiClient.postResponse = {
        'success': true,
        'device_id': '00000000-0000-4000-8000-000000000000',
        'device_token': 'new_token_123',
      };

      await service.registerDevice(
        deviceName: 'Pixel 8',
        platform: 'android',
      );

      final postedBody = apiClient.lastPostBody as Map<String, dynamic>;
      final sentDeviceId = postedBody['device_id'] as String;
      expect(sentDeviceId, isNot('legacy_non_uuid_123'));
      expect(sentDeviceId.length, 36);
      expect(sentDeviceId[14], '4');
    });
  });

  group('DeviceApiServiceImpl - updateDeviceName & updateFcmToken', () {
    test('updateDeviceName calls PUT and saves name to storage', () async {
      apiClient.putResponse = {'success': true};

      await service.updateDeviceName('New Name');

      expect(storage.deviceName, 'New Name');
      expect(apiClient.lastPutPath, ApiEndpoints.updateDeviceNameV2);
      expect(apiClient.lastPutBody, {'device_name': 'New Name'});
    });

    test('updateFcmToken calls PUT', () async {
      apiClient.putResponse = {'success': true};

      await service.updateFcmToken('fcm_token_123');

      expect(apiClient.lastPutPath, ApiEndpoints.updateFcmTokenV2);
      expect(apiClient.lastPutBody, {'fcm_token': 'fcm_token_123'});
    });
  });
}
