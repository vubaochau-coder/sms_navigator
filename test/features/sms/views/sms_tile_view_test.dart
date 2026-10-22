import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/channel_message_model.dart';
import 'package:sms_navigator/features/sms/views/sms_tile_view.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

void main() {
  final longBody = List.filled(30, 'Vietcombank thong bao ma OTP').join(' ');
  final message = ChannelMessageModel(
    messageId: 'm1',
    channelId: 'ch1',
    channelName: 'Kênh nhà',
    sequenceNumber: 1,
    keyEpoch: 1,
    ciphertext: 'x',
    nonce: 'y',
    sender: 'VCB',
    decryptedOtp: longBody,
  );

  Future<void> pumpTile(WidgetTester tester) => tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('vi'),
          home: Scaffold(body: SmsTileView(message: message)),
        ),
      );

  testWidgets('list tile clamps the message body to 2 lines', (tester) async {
    await pumpTile(tester);

    final body = tester.widget<Text>(find.text(longBody));
    expect(body.maxLines, 2);
    expect(body.overflow, TextOverflow.ellipsis);
  });

  testWidgets('detail bottom sheet shows the full message', (tester) async {
    await pumpTile(tester);

    await tester.tap(find.text(longBody));
    await tester.pumpAndSettle();

    final full = tester.widget<SelectableText>(find.byType(SelectableText));
    expect(full.data, longBody);
    expect(full.maxLines, isNull);
  });
}
