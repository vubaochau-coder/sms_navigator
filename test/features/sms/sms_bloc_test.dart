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

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<({List<ChannelMessageModel> messages, bool truncated})> fetchByDate({
    required DateTime date,
    int tzOffsetMinutes = 0,
  }) async {
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
    test('fetches messages for selected date', () async {
      final targetDate = DateTime(2026, 10, 4);
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

      bloc.add(SmsDateSelected(targetDate));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.messages.length, 1);
      expect(bloc.state.messages.first.decryptedOtp, '123456');
      expect(bloc.state.hasFetchedOnce, isTrue);
      expect(repository.lastFetchedDate, targetDate);
    });

    test('refreshes current date messages on SmsRefreshed', () async {
      repository.returnMessages = [
        const ChannelMessageModel(
          messageId: 'msg-1',
          channelId: 'ch-1',
          channelName: 'Channel A',
          sequenceNumber: 1,
          keyEpoch: 1,
          ciphertext: 'enc',
          nonce: 'nonce',
          decryptedOtp: '999888',
        ),
      ];

      bloc.add(const SmsRefreshed());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.messages.length, 1);
      expect(bloc.state.messages.first.decryptedOtp, '999888');
    });

    test('handles error gracefully without crashing and sets loading false', () async {
      repository.shouldFail = true;

      bloc.add(const SmsRefreshed());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.messages, isEmpty);
    });
  });
}
