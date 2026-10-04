import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_navigator/core/services/device_api_service.dart';
import 'package:sms_navigator/core/services/impls/device_storage_service_impl.dart';
import 'package:sms_navigator/core/services/impls/fcm_notification_service_impl.dart';
import 'package:sms_navigator/core/storage/local_storage_service.dart';

class _MockDeviceApiService implements DeviceApiService {
  String? updatedToken;

  @override
  Future<void> updateFcmToken(String fcmToken) async {
    updatedToken = fcmToken;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('FcmNotificationService v2 (Bell Only)', () {
    test('background message handler processes without exception', () async {
      const message = RemoteMessage(
        data: {'kind': 'NEW_MESSAGE', 'channel_id': 'ch_123'},
      );

      // Should complete without throwing
      await expectLater(
        firebaseMessagingBackgroundHandler(message),
        completes,
      );
    });

    test('service instantiates and disposes cleanly', () async {
      final localStorage = await LocalStorageService.create();
      final deviceStorage = DeviceStorageServiceImpl(localStorage);
      final deviceApi = _MockDeviceApiService();

      final service = FcmNotificationServiceImpl(
        deviceStorageService: deviceStorage,
        deviceApiService: deviceApi,
      );

      service.dispose();
      expect(service, isNotNull);
    });
  });
}
