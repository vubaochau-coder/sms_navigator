import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/features/channel/data/models/channel_message_model.dart';
import 'package:sms_navigator/features/channel/data/repositories/otp_by_date_repository.dart';
import 'package:sms_navigator/features/channel/presentation/bloc/otp_by_date_bloc.dart';

class _FakeOtpByDateRepository implements OtpByDateRepository {
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
  late _FakeOtpByDateRepository repository;
  late OtpByDateBloc bloc;

  setUp(() {
    repository = _FakeOtpByDateRepository();
    bloc = OtpByDateBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('OtpByDateBloc', () {
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

      bloc.add(OtpByDateSelected(targetDate));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.errorMessage, isNull);
      expect(bloc.state.messages.length, 1);
      expect(bloc.state.messages.first.decryptedOtp, '123456');
      expect(bloc.state.hasFetchedOnce, isTrue);
      expect(repository.lastFetchedDate, targetDate);
    });

    test('refreshes current date messages on OtpByDateRefreshed', () async {
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

      bloc.add(const OtpByDateRefreshed());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.messages.length, 1);
      expect(bloc.state.messages.first.decryptedOtp, '999888');
    });

    test('handles error gracefully with error message', () async {
      repository.shouldFail = true;

      bloc.add(const OtpByDateRefreshed());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.errorMessage, isNotNull);
      expect(bloc.state.messages, isEmpty);
    });
  });
}
