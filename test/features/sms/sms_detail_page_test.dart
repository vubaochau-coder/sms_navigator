import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/channel_message_model.dart';
import 'package:sms_navigator/features/sms/sms_detail_page.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      home: child,
    );

void main() {
  group('SmsDetailPage', () {
    testWidgets('renders all SMS details correctly with decrypted content', (
      tester,
    ) async {
      const message = ChannelMessageModel(
        messageId: 'msg_001',
        channelId: 'ch_001',
        channelName: 'Kênh Ngân Hàng',
        sequenceNumber: 1,
        keyEpoch: 1,
        ciphertext: 'cipher',
        nonce: 'nonce',
        sender: 'Vietcombank',
        senderDeviceId: 'pixel_8',
        serverReceivedAt: '2026-10-06T09:30:00Z',
        decryptedOtp: 'Ma OTP cua ban la 123456',
      );

      await tester.pumpWidget(_wrap(const SmsDetailPage(message: message)));
      await tester.pumpAndSettle();

      // Verify AppBar title
      expect(find.text('Chi tiết tin nhắn'), findsOneWidget);

      // Verify channel name
      expect(find.text('Kênh Ngân Hàng'), findsOneWidget);

      // Verify sender brand
      expect(find.text('Vietcombank'), findsOneWidget);

      // Verify sender device
      expect(find.text('pixel_8'), findsOneWidget);

      // Verify message content
      expect(find.text('Ma OTP cua ban la 123456'), findsOneWidget);

      // Verify copy button exists
      expect(find.byType(FilledButton), findsOneWidget);
      expect(find.text('Sao chép'), findsOneWidget);
    });

    testWidgets('renders decrypt error when content is null', (tester) async {
      const message = ChannelMessageModel(
        messageId: 'msg_002',
        channelId: 'ch_001',
        channelName: 'Kênh Test',
        sequenceNumber: 2,
        keyEpoch: 1,
        ciphertext: 'cipher',
        nonce: 'nonce',
        serverReceivedAt: '2026-10-06T09:30:00Z',
        decryptedOtp: null,
      );

      await tester.pumpWidget(_wrap(const SmsDetailPage(message: message)));
      await tester.pumpAndSettle();

      // Error message rendered instead of OTP
      expect(find.text('Không giải mã được tin này'), findsOneWidget);

      // Copy button should not be rendered
      expect(find.byType(FilledButton), findsNothing);
    });

    testWidgets('tapping copy button copies message to clipboard', (tester) async {
      const message = ChannelMessageModel(
        messageId: 'msg_003',
        channelId: 'ch_001',
        channelName: 'Kênh Test',
        sequenceNumber: 3,
        keyEpoch: 1,
        ciphertext: 'cipher',
        nonce: 'nonce',
        serverReceivedAt: '2026-10-06T09:30:00Z',
        decryptedOtp: '654321',
      );

      await tester.pumpWidget(_wrap(const SmsDetailPage(message: message)));
      await tester.pumpAndSettle();

      final copyButton = find.widgetWithText(FilledButton, 'Sao chép');
      expect(copyButton, findsOneWidget);
      await tester.tap(copyButton);
      await tester.pump();
    });
  });
}
