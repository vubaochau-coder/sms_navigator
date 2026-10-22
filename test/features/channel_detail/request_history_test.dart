import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/pairing_request_model.dart';
import 'package:sms_navigator/core/models/request_history_result.dart';
import 'package:sms_navigator/core/repositories/channel_repository.dart';
import 'package:sms_navigator/features/channel_detail/bloc/request_history_cubit.dart';
import 'package:sms_navigator/features/channel_detail/request_history_page.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

class _HistoryRepository implements ChannelRepository {
  final Map<String?, RequestHistoryResult> pages = {};
  final List<String?> cursors = [];
  Object? error;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<RequestHistoryResult> listRequestHistory(String channelId, {String? before}) async {
    cursors.add(before);
    if (error != null) throw error!;
    return pages[before] ?? const RequestHistoryResult();
  }
}

PairingRequestModel _req(String name, PairingRequestStatus status) => PairingRequestModel(
      requestId: 'r-$name',
      requesterDeviceName: name,
      status: status,
      createdAt: '2026-10-22T01:00:00Z',
      decidedAt: '2026-10-22T02:00:00Z',
    );

void main() {
  late _HistoryRepository repo;

  setUp(() {
    repo = _HistoryRepository()
      ..pages[null] = RequestHistoryResult(
        items: [_req('A', PairingRequestStatus.approved), _req('R', PairingRequestStatus.rejected)],
        nextBefore: 'cursor-1',
      )
      ..pages['cursor-1'] = RequestHistoryResult(items: [_req('C', PairingRequestStatus.cancelled)]);
  });

  test('load then loadMore appends the next page and stops at the end', () async {
    final cubit = RequestHistoryCubit(repository: repo, channelId: 'ch');
    await cubit.load();
    expect(cubit.state.items.map((r) => r.requesterDeviceName), ['A', 'R']);
    expect(cubit.state.hasMore, isTrue);

    await cubit.loadMore();
    expect(cubit.state.items.map((r) => r.requesterDeviceName), ['A', 'R', 'C']);
    expect(cubit.state.hasMore, isFalse);

    await cubit.loadMore(); // no cursor → no call
    expect(repo.cursors, [null, 'cursor-1']);
    await cubit.close();
  });

  test('a failed first load shows the error state', () async {
    repo.error = Exception('offline');
    final cubit = RequestHistoryCubit(repository: repo, channelId: 'ch');
    await cubit.load();
    expect(cubit.state.hasError, isTrue);
    await cubit.close();
  });

  testWidgets('renders one row per request with its status label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: RepositoryProvider<ChannelRepository>.value(
          value: repo,
          child: const RequestHistoryPage(channelId: 'ch'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Lịch sử yêu cầu kết nối'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);
    expect(find.text('Đã duyệt'), findsOneWidget);
    expect(find.text('Đã từ chối'), findsOneWidget);
    expect(find.text('Xem thêm'), findsOneWidget);

    await tester.tap(find.text('Xem thêm'));
    await tester.pumpAndSettle();
    expect(find.text('Đã huỷ'), findsOneWidget);
    expect(find.text('Xem thêm'), findsNothing);
  });
}
