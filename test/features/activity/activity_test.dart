import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/activity_item.dart';
import 'package:sms_navigator/core/models/channel_activity_entry.dart';
import 'package:sms_navigator/core/models/channel_event.dart';
import 'package:sms_navigator/core/models/relay_log_entry.dart';
import 'package:sms_navigator/core/repositories/impls/activity_repository_impl.dart';
import 'package:sms_navigator/core/services/channel_activity_log_store.dart';
import 'package:sms_navigator/core/services/native_relay_service.dart';
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
  });

  group('ActivityPage', () {
    Future<ActivityCubit> pumpPage(WidgetTester tester) async {
      final cubit = ActivityCubit(repository: repository);
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

    testWidgets('empty state', (tester) async {
      await pumpPage(tester);

      expect(find.text('Chưa có hoạt động'), findsOneWidget);
    });
  });
}
