import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/channel_message_model.dart';
import 'package:sms_navigator/core/notifications/notification_content.dart';

ChannelMessageModel _message({String? sender, required String text, String channelName = 'Kênh nhà'}) =>
    ChannelMessageModel(
      messageId: '',
      channelId: 'ch-1',
      channelName: channelName,
      sequenceNumber: 7,
      keyEpoch: 2,
      ciphertext: 'c',
      nonce: 'n',
      sender: sender,
      decryptedOtp: text,
    );

void main() {
  group('OtpNotificationContent', () {
    test('shows the code in the title and copies only the code', () {
      final content = OtpNotificationContent.fromMessage(
        _message(sender: 'VCB', text: 'Ma OTP cua quy khach la 482913'),
      );

      expect(content.code, '482913');
      expect(content.title, 'Mã OTP: 482913');
      expect(content.body, 'VCB: Ma OTP cua quy khach la 482913');
      expect(content.copyText, '482913');
      expect(content.channelName, 'Kênh nhà');
      expect(content.id, notificationIdFor('ch-1', 7));
      expect(content.payload, const NotificationPayload(channelId: 'ch-1', sequenceNumber: 7, copyText: '482913'));
    });

    test('no code → sender as title, full text copied', () {
      final content = OtpNotificationContent.fromMessage(
        _message(sender: 'Shop', text: 'Don hang da duoc giao', channelName: ''),
      );

      expect(content.code, isNull);
      expect(content.title, 'Shop');
      expect(content.body, 'Don hang da duoc giao');
      expect(content.copyText, 'Don hang da duoc giao');
      expect(content.channelName, isNull);
    });

    test('no code and no sender → generic title', () {
      final content = OtpNotificationContent.fromMessage(_message(text: 'Xin chao'));
      expect(content.title, 'Tin nhắn SMS mới');
    });
  });

  group('NotificationPayload', () {
    test('round-trips through encode/decode', () {
      const payload = NotificationPayload(channelId: 'ch', sequenceNumber: 3, copyText: '1234');
      expect(NotificationPayload.decode(payload.encode()), payload);
    });

    test('decode tolerates garbage', () {
      expect(NotificationPayload.decode(null), isNull);
      expect(NotificationPayload.decode(''), isNull);
      expect(NotificationPayload.decode('not json'), isNull);
      expect(NotificationPayload.decode('[1,2]'), isNull);
    });
  });

  test('notificationIdFor is stable, positive and distinguishes messages', () {
    expect(notificationIdFor('ch-1', 7), notificationIdFor('ch-1', 7));
    expect(notificationIdFor('ch-1', 7), isNot(notificationIdFor('ch-1', 8)));
    expect(notificationIdFor('ch-1', 7), greaterThanOrEqualTo(0));
    expect(notificationIdFor('ch-1', 7), lessThanOrEqualTo(0x7fffffff));
  });
}
