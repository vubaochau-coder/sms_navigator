import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_navigator/core/models/channel_event.dart';
import 'package:sms_navigator/core/models/channel_message_model.dart';
import 'package:sms_navigator/core/notifications/local_notification_presenter.dart';
import 'package:sms_navigator/core/notifications/notification_content.dart';
import 'package:sms_navigator/core/services/device_api_service.dart';
import 'package:sms_navigator/core/usecases/resolve_incoming_message_use_case.dart';
import 'package:sms_navigator/core/services/impls/device_storage_service_impl.dart';
import 'package:sms_navigator/core/services/impls/fcm_notification_service_impl.dart';
import 'package:sms_navigator/core/services/local_storage_service.dart';

class _MockDeviceApiService implements DeviceApiService {
  String? updatedToken;

  @override
  Future<void> updateFcmToken(String fcmToken) async {
    updatedToken = fcmToken;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePresenter implements LocalNotificationPresenter {
  final List<OtpNotificationContent> otps = [];
  final List<BellNotificationContent> bells = [];

  @override
  Future<void> showOtp(OtpNotificationContent content) async => otps.add(content);

  @override
  Future<void> showBell(BellNotificationContent content, {int? id, NotificationPayload? payload}) async =>
      bells.add(content);

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class _FakeResolve implements ResolveIncomingMessageUseCase {
  @override
  Future<ChannelMessageModel> call({required String channelId, required int sequenceNumber}) async =>
      ChannelMessageModel(
        messageId: '',
        channelId: channelId,
        channelName: 'Kênh nhà',
        sequenceNumber: sequenceNumber,
        keyEpoch: 1,
        ciphertext: 'c',
        nonce: 'n',
        sender: 'VCB',
        decryptedOtp: 'Ma OTP 482913',
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
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

    group('OTP notification + auto refresh (1.2 / 1.3)', () {
      late _FakePresenter presenter;
      late List<String> copied;
      late FcmNotificationServiceImpl service;

      setUp(() async {
        final localStorage = await LocalStorageService.create();
        presenter = _FakePresenter();
        copied = [];
        service = FcmNotificationServiceImpl(
          deviceStorageService: DeviceStorageServiceImpl(localStorage),
          deviceApiService: _MockDeviceApiService(),
          resolveIncomingMessage: _FakeResolve(),
          presenter: presenter,
          copyToClipboard: (text) async => copied.add(text),
        );
      });

      tearDown(() => service.dispose());

      test('foreground NEW_MESSAGE → emits a channel event and shows the OTP', () async {
        final events = <ChannelEvent>[];
        service.channelEvents.listen(events.add);

        await service.handleForegroundMessage(const RemoteMessage(
          data: {'kind': 'NEW_MESSAGE', 'channel_id': 'ch-1', 'sequence_number': '7', 'sender_device_id': 'owner-1'},
        ));
        await Future<void>.delayed(Duration.zero);

        expect(events.single.kind, ChannelEventKind.newMessage);
        expect(events.single.sequenceNumber, 7);
        expect(presenter.otps.single.title, 'Mã OTP: 482913');
        expect(presenter.bells, isEmpty);
      });

      test('foreground non-message event → generic bell', () async {
        await service.handleForegroundMessage(const RemoteMessage(data: {'kind': 'APPROVED'}));
        expect(presenter.bells.single.title, 'Yêu cầu đã được duyệt');
        expect(presenter.otps, isEmpty);
      });

      test('"Sao chép" action copies the code and asks screens to refresh', () async {
        final events = <ChannelEvent>[];
        service.channelEvents.listen(events.add);

        await service.handleNotificationResponse(NotificationResponse(
          notificationResponseType: NotificationResponseType.selectedNotificationAction,
          actionId: LocalNotificationPresenter.copyActionId,
          payload: const NotificationPayload(channelId: 'ch-1', sequenceNumber: 7, copyText: '482913').encode(),
        ));
        await Future<void>.delayed(Duration.zero);

        expect(copied, ['482913']);
        expect(events.single.openedFromNotification, isTrue);
        expect(events.single.channelId, 'ch-1');
      });

      test('plain tap refreshes but does not copy', () async {
        await service.handleNotificationResponse(NotificationResponse(
          notificationResponseType: NotificationResponseType.selectedNotification,
          payload: const NotificationPayload(channelId: 'ch-1', sequenceNumber: 7, copyText: '482913').encode(),
        ));
        expect(copied, isEmpty);
      });
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
        expect(result.body, 'Bạn đã được thêm vào kênh "Kênh OTP VIP". Mở app để xem tin nhắn SMS.');
      });

      test('APPROVED fallback without channel name', () {
        const message = RemoteMessage(
          data: {'kind': 'APPROVED'},
        );

        final result = FcmNotificationServiceImpl.resolveContent(message);
        expect(result.title, 'Yêu cầu đã được duyệt');
        expect(result.body, 'Bạn đã được thêm vào kênh. Mở app để bắt đầu nhận tin nhắn SMS.');
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
        expect(result.title, 'Tin nhắn SMS mới');
        expect(result.body, 'Có tin nhắn SMS mới từ kênh "Kênh Ngân Hàng". Chạm để xem.');
      });

      test('NEW_MESSAGE fallback without channel name', () {
        const message = RemoteMessage(
          data: {'kind': 'NEW_MESSAGE'},
        );

        final result = FcmNotificationServiceImpl.resolveContent(message);
        expect(result.title, 'Tin nhắn SMS mới');
        expect(result.body, 'Có tin nhắn SMS mới vừa được chia sẻ. Chạm để xem.');
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
