import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/activity_item.dart';
import 'package:sms_navigator/core/models/channel_activity_entry.dart';
import 'package:sms_navigator/core/models/channel_event.dart';
import 'package:sms_navigator/core/models/relay_log_entry.dart';
import 'package:sms_navigator/core/models/relay_sms_activity.dart';
import 'package:sms_navigator/core/repositories/impls/activity_repository_impl.dart';
import 'package:sms_navigator/core/services/channel_activity_log_store.dart';
import 'package:sms_navigator/core/services/native_relay_service.dart';
import 'package:sms_navigator/core/widgets/shimmer_loading.dart';
import 'package:sms_navigator/features/activity/activity_page.dart';
import 'package:sms_navigator/features/activity/bloc/activity_cubit.dart';
import 'package:sms_navigator/features/activity/bloc/activity_state.dart';
import 'package:sms_navigator/l10n/app_localizations.dart';

class _NativeRelay implements NativeRelayService {
  List<Map<String, dynamic>> logs = [];
  bool fail = false;

  @override
  Future<List<Map<String, dynamic>>> getRecentLogs() async {
    if (fail) throw Exception('channel gone');
    return logs;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class _LogStore implements ChannelActivityLogStore {
  final List<ChannelActivityEntry> entries = [];

  @override
  Future<void> record(ChannelEvent event, {DateTime? at}) async =>
      entries.insert(0, ChannelActivityEntry.fromEvent(event, at ?? DateTime(2026, 10, 22, 12)));

  @override
  Future<List<ChannelActivityEntry>> load() async => List.of(entries);
}

Map<String, dynamic> _log(String sender, String status, DateTime at) => {
  'id': sender,
  'sender': sender,
  'otp': '',
  'status': status,
  'error': '',
  'timestamp': at.millisecondsSinceEpoch,
};

/// Một dòng nhật ký native có `sms_id` + kênh (bản ghi mới, gom theo SMS).
Map<String, dynamic> _smsLog(
  String smsId,
  String status,
  DateTime at, {
  String channelId = '',
  String channelName = '',
  String otp = '',
  String error = '',
}) => {
  'id': '$smsId-$channelId-$status-${at.millisecondsSinceEpoch}',
  'sender': 'SSO',
  'otp': otp,
  'status': status,
  'error': error,
  'timestamp': at.millisecondsSinceEpoch,
  'sms_id': smsId,
  if (channelId.isNotEmpty) 'channel_id': channelId,
  if (channelName.isNotEmpty) 'channel_name': channelName,
};

void main() {
  late _NativeRelay native;
  late _LogStore logStore;
  late StreamController<ChannelEvent> events;
  late ActivityRepositoryImpl repository;

  setUp(() {
    native = _NativeRelay();
    logStore = _LogStore();
    events = StreamController<ChannelEvent>.broadcast();
    repository = ActivityRepositoryImpl(
      nativeRelayService: native,
      logStore: logStore,
      channelEvents: events.stream,
    );
  });

  tearDown(() async {
    await repository.dispose();
    await events.close();
  });

  group('ActivityRepositoryImpl', () {
    test('merges relay logs and channel events, newest first', () async {
      native.logs = [
        _log('VCB', 'SUCCESS', DateTime(2026, 10, 22, 10)),
        _log('TPB', 'BLOCKED', DateTime(2026, 10, 22, 8)),
      ];
      logStore.entries.add(ChannelActivityEntry(kind: ChannelEventKind.approved, at: DateTime(2026, 10, 22, 9)));

      final items = await repository.loadActivity();

      expect(items.map((item) => item.at?.hour), [10, 9, 8]);
      expect(items[0], isA<RelayActivityItem>());
      expect((items[0] as RelayActivityItem).entry.status, RelayLogStatus.success);
      expect(items[1], isA<ChannelActivityItem>());
    });

    test('collapses every log line of one SMS into a single item', () async {
      final t = DateTime(2026, 10, 23, 11, 19, 51);
      // Native ghi mới nhất trước.
      native.logs = [
        _smsLog('s1', 'SUCCESS', t.add(const Duration(seconds: 3)), channelId: 'c1', channelName: 'Châu và Diệp'),
        _smsLog('s1', 'BLOCKED', t, channelId: 'c2', channelName: 'VT', error: '[VT] WHITELIST_BLOCKED_EMPTY'),
        _smsLog('s1', 'ENQUEUED', t, channelId: 'c1', channelName: 'Châu và Diệp', otp: '8***6'),
        _log('Legacy', 'SUCCESS', DateTime(2026, 10, 22)),
      ];

      final items = await repository.loadActivity();

      expect(items, hasLength(2));
      final sms = (items.first as RelaySmsActivityItem).activity;
      expect(sms.at, t);
      expect(sms.detected, '8***6');
      expect(sms.outcome, RelaySmsOutcome.delivered);
      expect(sms.targets.single.channelName, 'Châu và Diệp');
      expect(items.last, isA<RelayActivityItem>());
    });

    test('outcome follows the latest line of each target channel', () {
      final t = DateTime(2026, 10, 23, 11);
      RelaySmsOutcome outcome(List<Map<String, dynamic>> logs) => RelaySmsActivity.fromEntries(
        's1',
        logs.map(RelayLogEntry.fromMap).toList(),
      ).outcome;
      Map<String, dynamic> line(String channel, String status, int second) =>
          _smsLog('s1', status, t.add(Duration(seconds: second)), channelId: channel, channelName: channel);

      expect(outcome([line('a', 'ENQUEUED', 0), line('b', 'ENQUEUED', 0)]), RelaySmsOutcome.sending);
      expect(outcome([line('a', 'ENQUEUED', 0), line('a', 'RETRYING', 1)]), RelaySmsOutcome.sending);
      expect(outcome([line('a', 'ENQUEUED', 0), line('a', 'PARKED', 1)]), RelaySmsOutcome.waiting);
      expect(
        outcome([line('a', 'ENQUEUED', 0), line('b', 'ENQUEUED', 0), line('a', 'SUCCESS', 1), line('b', 'FAILED', 2)]),
        RelaySmsOutcome.partial,
      );
      expect(outcome([line('a', 'ENQUEUED', 0), line('a', 'FAILED', 1)]), RelaySmsOutcome.failed);
      expect(outcome([line('a', 'BLOCKED', 0)]), RelaySmsOutcome.blocked);
      expect(outcome([_smsLog('s1', 'SKIPPED', t)]), RelaySmsOutcome.skipped);
      // Gửi lại sau khi đồng bộ khoá: dòng mới nhất là SUCCESS.
      expect(
        outcome([line('a', 'ENQUEUED', 0), line('a', 'PARKED', 1), line('a', 'SUCCESS', 9)]),
        RelaySmsOutcome.delivered,
      );
    });

    test('native failure still shows channel events', () async {
      native.fail = true;
      logStore.entries.add(ChannelActivityEntry(kind: ChannelEventKind.memberLeft, at: DateTime(2026)));

      expect(await repository.loadActivity(), hasLength(1));
    });

    test('records incoming channel events and announces a change', () async {
      final changed = repository.changes.first;

      events.add(const ChannelEvent(kind: ChannelEventKind.joinRequest, channelName: 'Nhà'));
      await changed;

      expect(logStore.entries.single.channelName, 'Nhà');
    });
  });

  group('ActivityCubit', () {
    test('refresh loads items; filter narrows them', () async {
      native.logs = [_log('VCB', 'SUCCESS', DateTime(2026, 10, 22, 10))];
      logStore.entries.add(ChannelActivityEntry(kind: ChannelEventKind.approved, at: DateTime(2026, 10, 22, 9)));
      final cubit = ActivityCubit(repository: repository);

      await cubit.refresh();
      expect(cubit.state.hasLoaded, isTrue);
      expect(cubit.state.visibleItems, hasLength(2));

      cubit.selectFilter(ActivityFilter.relay);
      expect(cubit.state.visibleItems.single, isA<RelayActivityItem>());
      cubit.selectFilter(ActivityFilter.channels);
      expect(cubit.state.visibleItems.single, isA<ChannelActivityItem>());
      await cubit.close();
    });

    test('relay filter keeps collapsed SMS items', () async {
      native.logs = [_smsLog('s1', 'ENQUEUED', DateTime(2026, 10, 23), channelId: 'c1')];
      final cubit = ActivityCubit(repository: repository)..selectFilter(ActivityFilter.relay);

      await cubit.refresh();
      expect(cubit.state.visibleItems.single, isA<RelaySmsActivityItem>());
      await cubit.close();
    });
  });

  group('ActivityPage', () {
    Future<ActivityCubit> pumpPage(WidgetTester tester) async {
      final cubit = ActivityCubit(repository: repository, minFeedbackDuration: Duration.zero);
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: Locale('vi'),
            home: ActivityPage(),
          ),
        ),
      );
      await tester.runAsync(cubit.refresh);
      await tester.pump();
      return cubit;
    }

    testWidgets('shows relay results and channel events in Vietnamese', (tester) async {
      native.logs = [_log('Vietcombank', 'SUCCESS', DateTime(2026, 10, 22, 10))];
      logStore.entries.add(ChannelActivityEntry(
        kind: ChannelEventKind.joinRequest,
        at: DateTime(2026, 10, 22, 9),
        channelName: 'Nhà',
        actorName: 'Pixel 8',
      ));
      await pumpPage(tester);

      expect(find.text('Vietcombank'), findsOneWidget);
      expect(find.text('Đã chuyển tiếp'), findsOneWidget);
      expect(find.text('Pixel 8 xin tham gia kênh "Nhà"'), findsOneWidget);

      await tester.tap(find.text('Kênh'));
      await tester.pump();
      expect(find.text('Vietcombank'), findsNothing);
      expect(find.text('Pixel 8 xin tham gia kênh "Nhà"'), findsOneWidget);
    });

    testWidgets('one row per SMS: "Đang gửi" until every channel is done', (tester) async {
      final t = DateTime(2026, 10, 23, 11, 19, 51);
      native.logs = [
        _smsLog('s1', 'BLOCKED', t, channelId: 'c2', channelName: 'VT'),
        _smsLog('s1', 'ENQUEUED', t, channelId: 'c1', channelName: 'Châu và Diệp', otp: '8***6'),
      ];
      final cubit = await pumpPage(tester);

      expect(find.text('SSO'), findsOneWidget);
      expect(find.text('Đang gửi'), findsOneWidget);
      expect(find.text('Bị lọc'), findsNothing);

      native.logs = [
        _smsLog('s1', 'SUCCESS', t.add(const Duration(seconds: 3)), channelId: 'c1', channelName: 'Châu và Diệp'),
        ...native.logs,
      ];
      await tester.runAsync(cubit.refresh);
      await tester.pump();

      expect(find.text('SSO'), findsOneWidget);
      expect(find.text('Đã gửi tới 1 kênh'), findsOneWidget);
      expect(find.text('Kênh: Châu và Diệp'), findsOneWidget);
      expect(find.text('Đang gửi'), findsNothing);
    });

    testWidgets('refresh button shows the shimmer right away', (tester) async {
      native.logs = [_log('Vietcombank', 'SUCCESS', DateTime(2026, 10, 22, 10))];
      await pumpPage(tester);
      expect(find.byType(ShimmerLoadingList), findsNothing);

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pump();
      expect(find.byType(ShimmerLoadingList), findsOneWidget);

      // Lần tải do nút bấm chạy trong fake-async của test → tự đẩy thời gian.
      await tester.pump(const Duration(milliseconds: 10));
      await tester.pump(const Duration(milliseconds: 10));
      expect(find.byType(ShimmerLoadingList), findsNothing);
      expect(find.text('Vietcombank'), findsOneWidget);
    });

    testWidgets('empty state', (tester) async {
      await pumpPage(tester);

      expect(find.text('Chưa có hoạt động'), findsOneWidget);
    });
  });
}
