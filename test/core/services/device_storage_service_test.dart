import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_navigator/core/services/impls/device_storage_service_impl.dart';
import 'package:sms_navigator/core/storage/local_storage_service.dart';
import 'package:sms_navigator/core/storage/secure_storage_service.dart';

class _FakeSecureStorageService implements SecureStorageService {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<bool> containsKey(String key) async => _data.containsKey(key);

  @override
  Future<void> delete(String key) async {
    _data.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService localStorage;
  late _FakeSecureStorageService secureStorage;
  late DeviceStorageServiceImpl service;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    localStorage = await LocalStorageService.create();
    secureStorage = _FakeSecureStorageService();
    service = DeviceStorageServiceImpl(
      localStorage,
      secureStorage: secureStorage,
    );
  });

  group('DeviceStorageService', () {
    test('saveDeviceToken and getDeviceToken round-trip', () async {
      await service.saveDeviceToken('tok_abc123');
      expect(await service.getDeviceToken(), 'tok_abc123');
    });

    test('clearDeviceToken removes device token from both secure and local storage', () async {
      await service.saveDeviceToken('tok_xyz999');
      expect(await service.getDeviceToken(), 'tok_xyz999');

      await service.clearDeviceToken();
      expect(await service.getDeviceToken(), isNull);
    });

    test('saveDeviceName and getDeviceName round-trip', () async {
      await service.saveDeviceName('Pixel 9 Pro');
      expect(await service.getDeviceName(), 'Pixel 9 Pro');
    });

    test('clearAll removes all device credentials and configuration', () async {
      await service.saveDeviceId('dev_1');
      await service.saveDeviceName('Pixel 9 Pro');
      await service.saveDeviceToken('tok_1');
      await service.saveServerUrl('https://example.com');
      await service.saveFcmToken('fcm_1');

      await service.clearAll();

      expect(await service.getDeviceId(), isNull);
      expect(await service.getDeviceName(), isNull);
      expect(await service.getDeviceToken(), isNull);
      expect(await service.getServerUrl(), isNull);
      expect(await service.getFcmToken(), isNull);
    });
  });
}
