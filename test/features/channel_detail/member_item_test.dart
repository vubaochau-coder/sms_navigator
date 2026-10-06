import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/channel_detail_model.dart';
import 'package:sms_navigator/core/models/channel_member_model.dart';
import 'package:sms_navigator/features/channel_detail/bloc/channel_detail_bloc.dart';
import 'package:sms_navigator/features/channel_detail/views/members_view.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

class _FakeChannelDetailBloc extends Cubit<ChannelDetailState>
    implements ChannelDetailBloc {
  _FakeChannelDetailBloc(super.initialState);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _ownerId = 'dev-owner-0001';
const _memberId = 'dev-member-b';

ChannelMemberModel _member(String id, {String status = 'ACTIVE'}) =>
    ChannelMemberModel(
      deviceId: id,
      deviceName: id == _ownerId ? 'Máy chủ' : 'Thành viên B',
      status: status,
      joinedEpoch: id == _ownerId ? 1 : 2,
    );

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('vi'),
      home: Scaffold(body: child),
    );

void main() {
  group('MemberItem — nhận diện Owner', () {
    testWidgets('owner: hiện badge Owner, ẩn nút thu hồi', (tester) async {
      await tester.pumpWidget(
        _wrap(MemberItem(member: _member(_ownerId), isOwner: true)),
      );

      expect(find.text('Owner'), findsOneWidget);
      expect(find.byIcon(Icons.workspace_premium_rounded), findsOneWidget);
      expect(find.byIcon(Icons.person_remove_rounded), findsNothing);
    });

    testWidgets('member thường: không có badge, hiện nút thu hồi',
        (tester) async {
      await tester.pumpWidget(
        _wrap(MemberItem(member: _member(_memberId), isOwner: false)),
      );

      expect(find.text('Owner'), findsNothing);
      expect(find.byIcon(Icons.person_remove_rounded), findsOneWidget);
    });

    testWidgets('member đã thu hồi: không có nút thu hồi', (tester) async {
      await tester.pumpWidget(
        _wrap(MemberItem(
          member: _member(_memberId, status: 'REVOKED'),
          isOwner: false,
        )),
      );

      expect(find.text('Đã thu hồi'), findsOneWidget);
      expect(find.byIcon(Icons.person_remove_rounded), findsNothing);
    });
  });

  group('MembersView — so khớp owner theo detail.ownerDeviceId', () {
    testWidgets('đúng member là Owner được gắn badge', (tester) async {
      final bloc = _FakeChannelDetailBloc(
        ChannelDetailState(
          channelId: 'ch1',
          detail: const ChannelDetailModel(
            channelId: 'ch1',
            name: 'Kênh nhà',
            ownerDeviceId: _ownerId,
          ),
          members: [_member(_ownerId), _member(_memberId)],
        ),
      );

      await tester.pumpWidget(
        _wrap(
          BlocProvider<ChannelDetailBloc>.value(
            value: bloc,
            child: const MembersView(),
          ),
        ),
      );

      expect(find.text('Thành viên (2)'), findsOneWidget);
      expect(find.text('Owner'), findsOneWidget);
      // Chỉ member thường có nút thu hồi
      expect(find.byIcon(Icons.person_remove_rounded), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await bloc.close();
    });
  });
}
