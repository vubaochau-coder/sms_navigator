import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
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
}
