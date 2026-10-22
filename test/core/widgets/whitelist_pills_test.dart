import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/channel_model.dart';
import 'package:sms_navigator/core/models/whitelist_config_model.dart';
import 'package:sms_navigator/core/widgets/whitelist_pills.dart';
import 'package:sms_navigator/features/channel/views/channel_card_view.dart';
import 'package:sms_navigator/features/channel_detail/views/channel_whitelist_section.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

WhitelistConfigModel _config(int count, {WhitelistMode mode = WhitelistMode.explicit}) => WhitelistConfigModel(
      mode: mode,
      entries: [
        for (var i = 1; i <= count; i++) WhitelistEntryModel(address: 'Brand$i', allowOtp: i == 1),
      ],
    );

Widget _app(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      home: Scaffold(body: child),
    );

void main() {
  group('WhitelistPillData.fromConfig', () {
    test('up to 3 entries → all shown', () {
      final pills = WhitelistPillData.fromConfig(_config(3), maxPills: 3);
      expect(pills.map((p) => p.label), ['Brand1', 'Brand2', 'Brand3']);
    });

    test('more than 3 → 2 entries + "+N" for the rest', () {
      expect(WhitelistPillData.fromConfig(_config(4), maxPills: 3).last, const WhitelistPillData.overflow(2));
      final pills = WhitelistPillData.fromConfig(_config(7), maxPills: 3);
      expect(pills, hasLength(3));
      expect(pills.take(2).map((p) => p.label), ['Brand1', 'Brand2']);
      expect(pills.last, const WhitelistPillData.overflow(5));
    });

    test('"all senders" mode is its own leading pill and counts toward the limit', () {
      final pills = WhitelistPillData.fromConfig(_config(3, mode: WhitelistMode.allAddresses), maxPills: 3);
      expect(pills.first, const WhitelistPillData.allSenders());
      expect(pills[1].label, 'Brand1');
      expect(pills.last, const WhitelistPillData.overflow(2));
    });

    test('no limit → every entry', () {
      expect(WhitelistPillData.fromConfig(_config(7)), hasLength(7));
    });
  });

  testWidgets('channel card shows at most 3 pills with "+N"', (tester) async {
    await tester.pumpWidget(_app(ChannelCardView(
      channel: ChannelModel(channelId: 'c', name: 'Nhà', role: ChannelRole.member, whitelist: _config(5)),
    )));

    expect(find.text('Brand1'), findsOneWidget);
    expect(find.text('Brand2'), findsOneWidget);
    expect(find.text('Brand3'), findsNothing);
    expect(find.text('+3'), findsOneWidget);
  });

  testWidgets('channel card without whitelist shows no pills', (tester) async {
    await tester.pumpWidget(_app(const ChannelCardView(
      channel: ChannelModel(channelId: 'c', name: 'Nhà', role: ChannelRole.member),
    )));

    expect(find.byType(WhitelistPills), findsNothing);
  });

  testWidgets('detail section lists every sender, marks OTP-allowed ones', (tester) async {
    await tester.pumpWidget(_app(ChannelWhitelistEntries(config: _config(5))));

    for (var i = 1; i <= 5; i++) {
      expect(find.text('Brand$i'), findsOneWidget);
    }
    expect(find.byIcon(Icons.key_rounded), findsOneWidget);
  });

  testWidgets('detail section: empty explicit list says so', (tester) async {
    await tester.pumpWidget(_app(const ChannelWhitelistEntries(config: WhitelistConfigModel())));

    expect(find.text('Chưa có người gửi nào trong bộ lọc'), findsOneWidget);
  });
}
