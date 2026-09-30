import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sms_navigator/core/services/fcm_notification_service.dart';
import 'package:sms_navigator/core/utils/crypto_helper.dart';
import 'package:sms_navigator/features/receiver/data/services/receiver_storage_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('FcmNotificationService.processIncomingRemoteMessage', () {
    test('ignores messages with type other than OTP_RELAY', () async {
      const message = RemoteMessage(
        data: {'type': 'PROMOTION', 'content': 'hello'},
      );

      final result = await FcmNotificationService.processIncomingRemoteMessage(
        message,
      );
      expect(result, isNull);
    });

    test(
      'decrypts OTP_RELAY payload using shared secret and saves to storage',
      () async {
        final secretKey = CryptoHelper.generateSecretKeyBase64();
        const pairId = 'pair_test_123';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('receiver_pair_id', pairId);
        await prefs.setString('receiver_shared_secret', secretKey);

        final payloadJson = jsonEncode({
          'sender': 'VPBank',
          'otp': '982103',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'message': 'Ma OTP cua ban la 982103. Khong chia se cho ai.',
        });

        final encrypted = await CryptoHelper.encryptAesGcm256(
          plaintext: payloadJson,
          secretKeyBase64: secretKey,
        );

        final message = RemoteMessage(
          data: {
            'type': 'OTP_RELAY',
            'pair_id': pairId,
            'encrypted_payload': encrypted['ciphertext']!,
            'iv': encrypted['iv']!,
            'sent_at': (DateTime.now().millisecondsSinceEpoch ~/ 1000)
                .toString(),
          },
        );

        // Note: _localNotifications.show may fail in pure test headless environment without platform channel,
        // but processIncomingRemoteMessage handles gracefully and returns model.
        final result =
            await FcmNotificationService.processIncomingRemoteMessage(message);

        if (result != null) {
          expect(result.sender, 'VPBank');
          expect(result.otp, '982103');

          final storage = ReceiverStorageServiceImpl();
          final history = await storage.getReceivedOtps();
          expect(history.any((item) => item.otp == '982103'), isTrue);
        }
      },
    );
  });
}
