import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/pairing_session_model.dart';
import 'package:sms_navigator/features/channel_detail/bloc/channel_invite_bloc.dart';
import 'package:sms_navigator/features/channel_detail/views/invite_bottom_sheet.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

class _FakeChannelInviteBloc extends Cubit<ChannelInviteState>
    implements ChannelInviteBloc {
  _FakeChannelInviteBloc(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      home: Scaffold(body: child),
    );

void main() {
  group('InviteBottomSheet', () {
    testWidgets('hiển thị nút Lưu mã QR khi có session', (tester) async {
      final bloc = _FakeChannelInviteBloc(
        ChannelInviteState(
          channelId: 'ch_001',
          session: PairingSessionModel(
            sessionId: 'ses_001',
            pairingToken: 'tok_001',
            expiresAt: DateTime.now()
                .add(const Duration(minutes: 9))
                .toIso8601String(),
            inviteUrl: 'smsnav://invite/v4?sid=ses_001',
          ),
        ),
      );

      await tester.pumpWidget(
        _wrap(
          BlocProvider<ChannelInviteBloc>.value(
            value: bloc,
            child: const InviteBottomSheet(),
          ),
        ),
      );

      expect(find.text('Mời thành viên'), findsOneWidget);
      expect(find.text('Lưu mã QR'), findsOneWidget);
      expect(find.text('Tạo lại mã'), findsOneWidget);
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await bloc.close();
    });
  });
}
