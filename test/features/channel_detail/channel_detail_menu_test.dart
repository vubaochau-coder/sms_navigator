import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/channel_detail_model.dart';
import 'package:sms_navigator/core/models/channel_member_model.dart';
import 'package:sms_navigator/core/models/channel_model.dart';
import 'package:sms_navigator/core/models/pairing_request_model.dart';
import 'package:sms_navigator/core/repositories/channel_repository.dart';
import 'package:sms_navigator/features/channel_detail/bloc/channel_detail_bloc.dart';
import 'package:sms_navigator/features/channel_detail/channel_detail_page.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

class _RenameRepository implements ChannelRepository {
  _RenameRepository({required this.role});

  final ChannelRole role;
  String name = 'Kênh cũ';
  Object? renameError;
  final List<String> renamedTo = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<ChannelDetailModel> getChannelDetail(String channelId) async =>
      ChannelDetailModel(channelId: channelId, name: name, myRole: role);

  @override
  Future<List<ChannelMemberModel>> getMembers(String channelId) async => const [];

  @override
  Future<List<PairingRequestModel>> listPendingRequests(String channelId) async => const [];

  @override
  Future<void> renameChannel({required String channelId, required String name}) async {
    renamedTo.add(name);
    final error = renameError;
    if (error != null) throw error;
    this.name = name;
  }
}

void main() {
  const channelId = 'ch_1';

  Future<ChannelDetailBloc> loadedBloc(_RenameRepository repo) async {
    final bloc = ChannelDetailBloc(repository: repo, channelId: channelId)
      ..add(const ChannelDetailLoaded(channelId));
    await pumpEventQueue();
    return bloc;
  }

  group('ChannelDetailRenamed (BACKLOG 1.5)', () {
    test('renames with the trimmed name and refreshes the detail', () async {
      final repo = _RenameRepository(role: ChannelRole.owner);
      final bloc = await loadedBloc(repo);

      bloc.add(const ChannelDetailRenamed('  Kênh VCB  '));
      await pumpEventQueue();

      expect(repo.renamedTo, ['Kênh VCB']);
      expect(bloc.state.detail?.name, 'Kênh VCB');
      expect(bloc.state.isMutating, isFalse);
      await bloc.close();
    });

    test('blank or unchanged names never reach the server', () async {
      final repo = _RenameRepository(role: ChannelRole.owner);
      final bloc = await loadedBloc(repo);

      bloc
        ..add(const ChannelDetailRenamed('   '))
        ..add(const ChannelDetailRenamed('Kênh cũ'));
      await pumpEventQueue();

      expect(repo.renamedTo, isEmpty);
      await bloc.close();
    });

    test('a failed rename keeps the old name and clears the busy flag', () async {
      final repo = _RenameRepository(role: ChannelRole.owner)..renameError = Exception('403 NOT_OWNER');
      final bloc = await loadedBloc(repo);

      bloc.add(const ChannelDetailRenamed('Kênh mới'));
      await pumpEventQueue();

      expect(bloc.state.detail?.name, 'Kênh cũ');
      expect(bloc.state.isMutating, isFalse);
      await bloc.close();
    });
  });

  group('ChannelDetailMenuButton', () {
    Future<void> pump(WidgetTester tester, ChannelDetailBloc bloc) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider.value(
            value: bloc,
            child: Scaffold(appBar: AppBar(actions: const [ChannelDetailMenuButton()])),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // Không await bloc.close() trong FakeAsync của testWidgets — treo test.
    ChannelDetailBloc blocFor(ChannelRole role) =>
        ChannelDetailBloc(repository: _RenameRepository(role: role), channelId: channelId)
          ..add(const ChannelDetailLoaded(channelId));

    testWidgets('owner sees "Đổi tên kênh" and "Giải tán kênh"', (tester) async {
      final bloc = blocFor(ChannelRole.owner);
      await pump(tester, bloc);

      await tester.tap(find.byTooltip('Tùy chọn kênh'));
      await tester.pumpAndSettle();
      expect(find.text('Đổi tên kênh'), findsOneWidget);
      expect(find.text('Giải tán kênh'), findsOneWidget);
      expect(find.text('Rời kênh'), findsNothing);
    });

    testWidgets('a member only sees "Rời kênh"', (tester) async {
      final bloc = blocFor(ChannelRole.member);
      await pump(tester, bloc);

      await tester.tap(find.byTooltip('Tùy chọn kênh'));
      await tester.pumpAndSettle();
      expect(find.text('Rời kênh'), findsOneWidget);
      expect(find.text('Đổi tên kênh'), findsNothing);
      expect(find.text('Giải tán kênh'), findsNothing);
    });
  });
}
