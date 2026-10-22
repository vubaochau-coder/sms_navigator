import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/channel_detail_model.dart';
import 'package:sms_navigator/core/models/channel_member_model.dart';
import 'package:sms_navigator/core/models/channel_model.dart';
import 'package:sms_navigator/core/models/pairing_request_model.dart';
import 'package:sms_navigator/core/repositories/channel_repository.dart';
import 'package:sms_navigator/features/channel_detail/bloc/channel_detail_bloc.dart';

class _LifecycleRepository implements ChannelRepository {
  _LifecycleRepository(this.role);

  final ChannelRole role;
  Object? error;
  final List<String> calls = [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<ChannelDetailModel> getChannelDetail(String channelId) async =>
      ChannelDetailModel(channelId: channelId, name: 'Kênh nhà', myRole: role);

  @override
  Future<List<ChannelMemberModel>> getMembers(String channelId) async => const [];

  @override
  Future<List<PairingRequestModel>> listPendingRequests(String channelId) async => const [];

  @override
  Future<void> leaveChannel(String channelId) async {
    calls.add('leave:$channelId');
    if (error != null) throw error!;
  }

  @override
  Future<void> archiveChannel(String channelId) async {
    calls.add('archive:$channelId');
    if (error != null) throw error!;
  }
}

void main() {
  const channelId = 'ch_1';

  Future<ChannelDetailBloc> loaded(_LifecycleRepository repo) async {
    final bloc = ChannelDetailBloc(repository: repo, channelId: channelId)
      ..add(const ChannelDetailLoaded(channelId));
    await pumpEventQueue();
    return bloc;
  }

  test('member leaves → repository.leaveChannel, page closes', () async {
    final repo = _LifecycleRepository(ChannelRole.member);
    final bloc = await loaded(repo);

    bloc.add(const ChannelDetailLeft());
    await pumpEventQueue();

    expect(repo.calls, ['leave:$channelId']);
    expect(bloc.state.isClosed, isTrue);
    expect(bloc.state.isMutating, isFalse);
    await bloc.close();
  });

  test('owner archives → repository.archiveChannel, page closes', () async {
    final repo = _LifecycleRepository(ChannelRole.owner);
    final bloc = await loaded(repo);

    bloc.add(const ChannelDetailArchived());
    await pumpEventQueue();

    expect(repo.calls, ['archive:$channelId']);
    expect(bloc.state.isClosed, isTrue);
    await bloc.close();
  });

  test('a failed leave / archive keeps the page open', () async {
    final repo = _LifecycleRepository(ChannelRole.owner)..error = Exception('offline');
    final bloc = await loaded(repo);

    bloc.add(const ChannelDetailArchived());
    await pumpEventQueue();
    expect(bloc.state.isClosed, isFalse);
    expect(bloc.state.isMutating, isFalse);

    bloc.add(const ChannelDetailLeft());
    await pumpEventQueue();
    expect(bloc.state.isClosed, isFalse);
    await bloc.close();
  });

  test('detail model parses rotation_pending and archived status', () {
    final detail = ChannelDetailModel.fromMap({
      'channel': {'channel_id': channelId, 'name': 'X', 'status': 'ARCHIVED'},
      'my_role': 'OWNER',
      'rotation_pending': true,
    });
    expect(detail.rotationPending, isTrue);
    expect(detail.isArchived, isTrue);
    expect(ChannelDetailModel.fromMap(const {'channel': {}}).rotationPending, isFalse);
  });
}
