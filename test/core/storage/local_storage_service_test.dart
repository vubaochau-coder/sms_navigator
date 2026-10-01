import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_navigator/core/storage/local_storage_service.dart';
import 'package:sms_navigator/core/storage/storage_keys.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storage;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    storage = await LocalStorageService.create();
  });

  group('LocalStorageServiceImpl', () {
    test('create() returns a working instance', () {
      expect(storage, isA<LocalStorageServiceImpl>());
    });

    test('setString/getString round-trips a value', () async {
      await storage.setString(StorageKeys.deviceId, 'device_123');

      expect(storage.getString(StorageKeys.deviceId), 'device_123');
    });

    test('getString returns null for missing key', () {
      expect(storage.getString(StorageKeys.deviceToken), isNull);
    });

    test('setBool/getBool round-trips a value', () async {
      expect(storage.getBool(StorageKeys.autostartAcknowledged), isNull);

      await storage.setBool(StorageKeys.autostartAcknowledged, true);

      expect(storage.getBool(StorageKeys.autostartAcknowledged), isTrue);
    });

    test('setString overwrites previous value', () async {
      await storage.setString(StorageKeys.fcmToken, 'old_token');
      await storage.setString(StorageKeys.fcmToken, 'new_token');

      expect(storage.getString(StorageKeys.fcmToken), 'new_token');
    });

    test('remove deletes the stored value', () async {
      await storage.setString(StorageKeys.serverUrl, 'https://example.com');

      await storage.remove(StorageKeys.serverUrl);

      expect(storage.getString(StorageKeys.serverUrl), isNull);
    });

    test('remove on missing key completes without error', () async {
      await expectLater(
        storage.remove(StorageKeys.themeMode),
        completes,
      );
    });
  });
}
