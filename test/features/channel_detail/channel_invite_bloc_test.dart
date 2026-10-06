import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/pairing_request_model.dart';
import 'package:sms_navigator/core/models/pairing_session_model.dart';
import 'package:sms_navigator/core/repositories/channel_repository.dart';
import 'package:sms_navigator/features/channel_detail/bloc/channel_invite_bloc.dart';

class _MockChannelRepository implements ChannelRepository {
  int createCallCount = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<PairingSessionModel> createPairingSession(String channelId) async {
    createCallCount++;
    return PairingSessionModel(
      sessionId: 'ses_$createCallCount',
      pairingToken: 'tok_$createCallCount',
      expiresAt: DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
      inviteUrl: 'smsnav://invite/v4?s=ses_$createCallCount',
    );
  }
}

void main() {
  group('ChannelInviteBloc — active session reuse & regeneration', () {
    const channelId = 'ch_test_reuse';
    late _MockChannelRepository repository;

    setUp(() {
      repository = _MockChannelRepository();
      ChannelInviteBloc.invalidateCache(channelId);
    });

    test('tái sử dụng session còn hạn khi mở lại sheet thay vì gọi API mới', () async {
      // 1. Lần mở sheet đầu tiên -> gọi API tạo session #1
      final bloc1 = ChannelInviteBloc(repository: repository, channelId: channelId);
      bloc1.add(const ChannelInviteStarted());
      await pumpEventQueue();

      expect(repository.createCallCount, 1);
      expect(bloc1.state.session?.sessionId, 'ses_1');
      await bloc1.close();

      // 2. Lần mở sheet thứ 2 -> tái sử dụng session #1, không gọi API
      final bloc2 = ChannelInviteBloc(repository: repository, channelId: channelId);
      bloc2.add(const ChannelInviteStarted());
      await pumpEventQueue();

      expect(repository.createCallCount, 1); // Không tăng
      expect(bloc2.state.session?.sessionId, 'ses_1');
      await bloc2.close();
    });

    test('tạo session mới khi bấm tạo lại mã (regenerate)', () async {
      final bloc = ChannelInviteBloc(repository: repository, channelId: channelId);
      bloc.add(const ChannelInviteStarted());
      await pumpEventQueue();
      expect(repository.createCallCount, 1);
      expect(bloc.state.session?.sessionId, 'ses_1');

      // Bấm tạo lại mã -> gọi API sinh session #2
      bloc.add(const ChannelInviteRegenerated());
      await pumpEventQueue();
      expect(repository.createCallCount, 2);
      expect(bloc.state.session?.sessionId, 'ses_2');

      await bloc.close();
    });

    test('invalidateIfConsumed hủy cache khi phát hiện request được tạo sau session', () async {
      final now = DateTime.now();
      final bloc = ChannelInviteBloc(repository: repository, channelId: channelId);
      bloc.add(const ChannelInviteStarted());
      await pumpEventQueue();
      expect(repository.createCallCount, 1);
      await bloc.close();

      // Request được tạo sau khi tạo session (QR đã bị claim)
      final newerRequest = PairingRequestModel(
        requestId: 'req_newer',
        createdAt: now.add(const Duration(seconds: 10)).toIso8601String(),
      );
      ChannelInviteBloc.invalidateIfConsumed(channelId, [newerRequest]);

      // Mở lại sheet -> cache đã bị xóa -> gọi API tạo session mới
      final bloc2 = ChannelInviteBloc(repository: repository, channelId: channelId);
      bloc2.add(const ChannelInviteStarted());
      await pumpEventQueue();

      expect(repository.createCallCount, 2);
      expect(bloc2.state.session?.sessionId, 'ses_2');
      await bloc2.close();
    });

    test('invalidateIfConsumed giữ nguyên cache khi pending request là request cũ từ trước session', () async {
      final now = DateTime.now();
      final bloc = ChannelInviteBloc(repository: repository, channelId: channelId);
      bloc.add(const ChannelInviteStarted());
      await pumpEventQueue();
      expect(repository.createCallCount, 1);
      await bloc.close();

      // Request cũ được tạo trước khi tạo session
      final olderRequest = PairingRequestModel(
        requestId: 'req_older',
        createdAt: now.subtract(const Duration(minutes: 5)).toIso8601String(),
      );
      ChannelInviteBloc.invalidateIfConsumed(channelId, [olderRequest]);

      // Mở lại sheet -> cache vẫn còn -> không gọi API mới
      final bloc2 = ChannelInviteBloc(repository: repository, channelId: channelId);
      bloc2.add(const ChannelInviteStarted());
      await pumpEventQueue();

      expect(repository.createCallCount, 1);
      expect(bloc2.state.session?.sessionId, 'ses_1');
      await bloc2.close();
    });
  });
}
