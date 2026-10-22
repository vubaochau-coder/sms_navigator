import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/channel_event.dart';
import 'package:sms_navigator/core/models/channel_message_model.dart';
import 'package:sms_navigator/core/repositories/sms_by_date_repository.dart';
import 'package:sms_navigator/features/sms/bloc/sms_bloc.dart';

class _FakeSmsByDateRepository implements SmsByDateRepository {
  List<ChannelMessageModel> returnMessages = [];
  bool returnTruncated = false;
  bool shouldFail = false;
  DateTime? lastFetchedDate;
  int? lastTzOffset;
  int fetchCallCount = 0;
  final StreamController<ChannelEvent> changes = StreamController<ChannelEvent>.broadcast();

  @override
  Stream<ChannelEvent> get messageChanges => changes.stream;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<({List<ChannelMessageModel> messages, bool truncated})> fetchByDate({
    required DateTime date,
    int tzOffsetMinutes = 0,
    CancelToken? cancelToken,
  }) async {
    fetchCallCount++;
    if (shouldFail) throw Exception('Fetch failed');
    lastFetchedDate = date;
    lastTzOffset = tzOffsetMinutes;
    return (messages: returnMessages, truncated: returnTruncated);
  }
}

void main() {
  late _FakeSmsByDateRepository repository;
  late SmsBloc bloc;

  setUp(() {
    repository = _FakeSmsByDateRepository();
    bloc = SmsBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('SmsBloc', () {
    test('SmsLoadDataEvent fetches messages for current state date', () async {
      repository.returnMessages = [
        const ChannelMessageModel(
          messageId: 'msg-1',
          channelId: 'ch-1',
          channelName: 'Channel A',
          sequenceNumber: 1,
          keyEpoch: 1,
          ciphertext: 'enc',
          nonce: 'nonce',
          decryptedOtp: '123456',
        ),
      ];

      bloc.add(const SmsLoadDataEvent());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.messages.length, 1);
      expect(bloc.state.messages.first.decryptedOtp, '123456');
      expect(bloc.state.hasFetchedOnce, isTrue);
      expect(repository.fetchCallCount, 1);
    });

    test('SmsDateSelected emits new date and automatically triggers SmsLoadDataEvent when date is different', () async {
      final newDate = DateTime(2025, 5, 20);
      repository.returnMessages = [
        const ChannelMessageModel(
          messageId: 'msg-2',
          channelId: 'ch-2',
          channelName: 'Channel B',
          sequenceNumber: 2,
          keyEpoch: 1,
          ciphertext: 'enc',
          nonce: 'nonce',
          decryptedOtp: '888999',
        ),
      ];

      bloc.add(SmsDateSelected(newDate));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.selectedDate, newDate);
      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.messages.length, 1);
      expect(bloc.state.messages.first.decryptedOtp, '888999');
      expect(repository.lastFetchedDate, newDate);
      expect(repository.fetchCallCount, 1);
    });

    test('SmsDateSelected does NOT load or emit if selected date is same day', () async {
      final currentDate = bloc.state.selectedDate;
      // Chọn lại đúng ngày hiện tại (chỉ khác giờ phút)
      final sameDayDate = DateTime(
        currentDate.year,
        currentDate.month,
        currentDate.day,
        12,
        0,
      );

      bloc.add(SmsDateSelected(sameDayDate));
      await Future<void>.delayed(Duration.zero);

      expect(repository.fetchCallCount, 0);
    });

    test('handles error gracefully without crashing and sets loading false', () async {
      repository.shouldFail = true;

      bloc.add(const SmsLoadDataEvent());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.messages, isEmpty);
    });
  });

  group('SmsBloc auto refresh (1.3)', () {
    final today = DateTime(2026, 10, 21, 9, 30);
    late _FakeSmsByDateRepository repo;
    late SmsBloc autoBloc;
    late List<SmsState> states;
    late StreamSubscription<SmsState> stateSub;

    const message = ChannelMessageModel(
      messageId: 'msg-1',
      channelId: 'ch-1',
      channelName: 'Kênh',
      sequenceNumber: 1,
      keyEpoch: 1,
      ciphertext: 'enc',
      nonce: 'nonce',
      decryptedOtp: '123456',
    );

    Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 1));

    setUp(() async {
      repo = _FakeSmsByDateRepository()..returnMessages = [message];
      autoBloc = SmsBloc(repository: repo, clock: () => today);
      autoBloc.add(const SmsLoadDataEvent());
      await settle();
      states = [];
      stateSub = autoBloc.stream.listen(states.add);
    });

    tearDown(() async {
      await stateSub.cancel();
      await autoBloc.close();
      await repo.changes.close();
    });

    test('NEW_MESSAGE while viewing today → silent refetch, no shimmer', () async {
      repo.changes.add(const ChannelEvent(kind: ChannelEventKind.newMessage, channelId: 'ch-1'));
      await settle();

      expect(repo.fetchCallCount, 2);
      expect(states.where((s) => s.isLoading), isEmpty);
      expect(autoBloc.state.messages, [message]);
    });

    test('NEW_MESSAGE while viewing another day → no refetch', () async {
      autoBloc.add(SmsDateSelected(DateTime(2026, 10, 1)));
      await settle();
      final before = repo.fetchCallCount;

      repo.changes.add(const ChannelEvent(kind: ChannelEventKind.newMessage, channelId: 'ch-1'));
      await settle();

      expect(repo.fetchCallCount, before);
    });

    test('REVOKED refreshes whatever day is selected', () async {
      autoBloc.add(SmsDateSelected(DateTime(2026, 10, 1)));
      await settle();
      final before = repo.fetchCallCount;

      repo.changes.add(const ChannelEvent(kind: ChannelEventKind.revoked, channelId: 'ch-1'));
      await settle();

      expect(repo.fetchCallCount, before + 1);
      expect(repo.lastFetchedDate, DateTime(2026, 10, 1));
    });

    test('silent refresh failure keeps the current list and never shows loading', () async {
      repo.shouldFail = true;
      repo.changes.add(const ChannelEvent(kind: ChannelEventKind.newMessage));
      await settle();

      expect(states.where((s) => s.isLoading), isEmpty);
      expect(autoBloc.state.messages, [message]);
    });

    test('SmsAppResumed refreshes silently once data was loaded', () async {
      autoBloc.add(const SmsAppResumed());
      await settle();

      expect(repo.fetchCallCount, 2);
      expect(states.where((s) => s.isLoading), isEmpty);
    });

    test('SmsAppResumed before the first load does nothing', () async {
      final fresh = _FakeSmsByDateRepository();
      final freshBloc = SmsBloc(repository: fresh, clock: () => today);
      freshBloc.add(const SmsAppResumed());
      await settle();

      expect(fresh.fetchCallCount, 0);
      await freshBloc.close();
      await fresh.changes.close();
    });

    test('stops listening for changes after close', () async {
      await autoBloc.close();
      expect(repo.changes.hasListener, isFalse);
    });
  });
}
