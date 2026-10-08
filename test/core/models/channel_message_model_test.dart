import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/channel_message_model.dart';

void main() {
  group('ChannelMessageModel', () {
    const baseMessage = ChannelMessageModel(
      messageId: 'msg_1',
      channelId: 'ch_1',
      channelName: 'Kênh Test',
      sequenceNumber: 1,
      keyEpoch: 1,
      ciphertext: 'ciphertext_base64',
      nonce: 'nonce_base64',
      senderDeviceId: 'device_owner_a',
      sentAt: '2026-10-08T00:00:00.000Z',
      serverReceivedAt: '2026-10-08T00:00:01.000Z',
    );

    test('copyWithDecrypted extracts sender and fullMessage from JSON payload', () {
      final jsonPayload = jsonEncode({
        'sender': 'SSO',
        'fullMessage': 'Mã xác thực của bạn là 654321',
      });

      final decrypted = baseMessage.copyWithDecrypted(jsonPayload);

      expect(decrypted.sender, 'SSO');
      expect(decrypted.decryptedOtp, 'Mã xác thực của bạn là 654321');
      expect(decrypted.decryptFailed, false);
      expect(decrypted.senderDeviceId, 'device_owner_a');
    });

    test('copyWithDecrypted maintains backward compatibility with raw text', () {
      const rawText = 'Mã xác thực của bạn là 123456';

      final decrypted = baseMessage.copyWithDecrypted(rawText);

      expect(decrypted.sender, isNull);
      expect(decrypted.decryptedOtp, 'Mã xác thực của bạn là 123456');
      expect(decrypted.decryptFailed, false);
    });

    test('copyWithDecrypted supports otp fallback key in JSON', () {
      final jsonPayload = jsonEncode({
        'sender': 'Vietcombank',
        'otp': '999888',
      });

      final decrypted = baseMessage.copyWithDecrypted(jsonPayload);

      expect(decrypted.sender, 'Vietcombank');
      expect(decrypted.decryptedOtp, '999888');
    });
  });
}
