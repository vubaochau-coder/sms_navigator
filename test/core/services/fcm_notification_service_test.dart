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

    group('resolveContent notification test matrix', () {
      test('prioritizes server notification block over data payload', () {
        const message = RemoteMessage(
          notification: RemoteNotification(
            title: 'Server Title',
            body: 'Server Body from notification block',
          ),
          data: {
            'kind': 'JOIN_REQUEST',
            'channel_name': 'Kênh X',
            'requester_device_name': 'Bob',
          },
        );

        final result = FcmNotificationServiceImpl.resolveContent(message);
        expect(result.title, 'Server Title');
        expect(result.body, 'Server Body from notification block');
      });

      test('JOIN_REQUEST with both requester name and channel name', () {
        const message = RemoteMessage(
          data: {
            'kind': 'JOIN_REQUEST',
            'requester_device_name': 'Alice',
            'channel_name': 'Kênh OTP',
          },
        );

        final result = FcmNotificationServiceImpl.resolveContent(message);
        expect(result.title, 'Yêu cầu tham gia kênh');
        expect(result.body, 'Alice muốn tham gia kênh "Kênh OTP".');
      });

      test('JOIN_REQUEST with requester name only', () {
        const message = RemoteMessage(
          data: {
            'kind': 'JOIN_REQUEST',
            'requester_device_name': 'Alice',
          },
        );

        final result = FcmNotificationServiceImpl.resolveContent(message);
        expect(result.title, 'Yêu cầu tham gia kênh');
        expect(result.body, 'Alice muốn tham gia kênh.');
      });

      test('JOIN_REQUEST fallback without requester or channel', () {
        const message = RemoteMessage(
          data: {'kind': 'JOIN_REQUEST'},
        );

        final result = FcmNotificationServiceImpl.resolveContent(message);
        expect(result.title, 'Yêu cầu tham gia kênh');
        expect(result.body, 'Có thiết bị mới xin tham gia. Mở app để duyệt.');
      });

      test('APPROVED with channel name', () {
        const message = RemoteMessage(
          data: {
            'kind': 'APPROVED',
            'channel_name': 'Kênh OTP VIP',
          },
        );

        final result = FcmNotificationServiceImpl.resolveContent(message);
        expect(result.title, 'Yêu cầu đã được duyệt');
        expect(result.body, 'Bạn đã được thêm vào kênh "Kênh OTP VIP". Mở app để xem OTP.');
      });

      test('APPROVED fallback without channel name', () {
        const message = RemoteMessage(
          data: {'kind': 'APPROVED'},
        );

        final result = FcmNotificationServiceImpl.resolveContent(message);
        expect(result.title, 'Yêu cầu đã được duyệt');
        expect(result.body, 'Bạn đã được thêm vào kênh. Mở app để bắt đầu nhận OTP.');
      });

      test('REVOKED with channel name', () {
        const message = RemoteMessage(
          data: {
            'kind': 'REVOKED',
            'channel_name': 'Kênh Cũ',
          },
        );

        final result = FcmNotificationServiceImpl.resolveContent(message);
        expect(result.title, 'Quyền truy cập đã bị thu hồi');
        expect(result.body, 'Bạn không còn quyền truy cập kênh "Kênh Cũ".');
      });

      test('REVOKED fallback without channel name', () {
        const message = RemoteMessage(
          data: {'kind': 'REVOKED'},
        );

        final result = FcmNotificationServiceImpl.resolveContent(message);
        expect(result.title, 'Quyền truy cập đã bị thu hồi');
        expect(result.body, 'Bạn không còn quyền truy cập một kênh.');
      });

      test('NEW_MESSAGE with channel name', () {
        const message = RemoteMessage(
          data: {
            'kind': 'NEW_MESSAGE',
            'channel_name': 'Kênh Ngân Hàng',
          },
        );

        final result = FcmNotificationServiceImpl.resolveContent(message);
        expect(result.title, 'OTP mới');
        expect(result.body, 'Có mã OTP mới từ kênh "Kênh Ngân Hàng". Chạm để xem.');
      });

      test('NEW_MESSAGE fallback without channel name', () {
        const message = RemoteMessage(
          data: {'kind': 'NEW_MESSAGE'},
        );

        final result = FcmNotificationServiceImpl.resolveContent(message);
        expect(result.title, 'OTP mới');
        expect(result.body, 'Có mã OTP mới vừa được chia sẻ. Chạm để xem.');
      });

      test('Unknown kind falls back to default app notification', () {
        const message = RemoteMessage(
          data: {'kind': 'UNKNOWN_EVENT'},
        );

        final result = FcmNotificationServiceImpl.resolveContent(message);
        expect(result.title, 'SMS Navigator');
        expect(result.body, 'Có sự kiện mới trong kênh. Mở app để xem.');
      });
    });
  });
}
