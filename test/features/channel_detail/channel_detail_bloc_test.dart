import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/channel_detail_model.dart';
import 'package:sms_navigator/core/models/channel_member_model.dart';
import 'package:sms_navigator/core/models/channel_model.dart';
import 'package:sms_navigator/core/models/pairing_request_model.dart';
import 'package:sms_navigator/core/repositories/channel_repository.dart';
import 'package:sms_navigator/features/channel_detail/bloc/channel_detail_bloc.dart';

class _MockChannelRepository implements ChannelRepository {
  ChannelDetailModel detailToReturn = const ChannelDetailModel(
    channelId: 'ch_1',
    name: 'Kênh Test',
    myRole: ChannelRole.member,
  );
  List<ChannelMemberModel> membersToReturn = const [
    ChannelMemberModel(
      deviceId: 'dev_1',
      deviceName: 'Máy 1',
      status: 'ACTIVE',
      joinedEpoch: 1,
    ),
  ];
  List<PairingRequestModel> pendingToReturn = const [
    PairingRequestModel(
      requestId: 'req_1',
      channelId: 'ch_1',
      requesterDeviceId: 'dev_2',
      requesterDeviceName: 'Máy 2',
      status: PairingRequestStatus.pending,
      createdAt: '2026-10-07T00:00:00Z',
    ),
  ];

  int listPendingRequestsCallCount = 0;
  bool shouldThrowOnListPending = false;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<ChannelDetailModel> getChannelDetail(String channelId) async =>
      detailToReturn;

  @override
  Future<List<ChannelMemberModel>> getMembers(String channelId) async =>
      membersToReturn;

  @override
  Future<List<PairingRequestModel>> listPendingRequests(String channelId) async {
    listPendingRequestsCallCount++;
    if (shouldThrowOnListPending) {
      throw Exception('403 NOT_OWNER: Only channel owner can view approval queue');
    }
    return pendingToReturn;
  }
}

void main() {
  group('ChannelDetailBloc — role gating & pending requests', () {
    const channelId = 'ch_1';
    late _MockChannelRepository repository;

    setUp(() {
      repository = _MockChannelRepository();
    });

    test('Member mở detail: không gọi listPendingRequests, pendingRequests rỗng', () async {
      repository.detailToReturn = const ChannelDetailModel(
        channelId: channelId,
        name: 'Kênh Member',
        myRole: ChannelRole.member,
      );

      final bloc = ChannelDetailBloc(repository: repository, channelId: channelId);
      bloc.add(const ChannelDetailLoaded(channelId));
      await pumpEventQueue();

      expect(repository.listPendingRequestsCallCount, 0);
      expect(bloc.state.isLoading, false);
      expect(bloc.state.detail?.name, 'Kênh Member');
      expect(bloc.state.members.length, 1);
      expect(bloc.state.pendingRequests, isEmpty);
      await bloc.close();
    });

    test('Owner mở detail: gọi listPendingRequests và nạp danh sách chờ duyệt', () async {
      repository.detailToReturn = const ChannelDetailModel(
        channelId: channelId,
        name: 'Kênh Owner',
        myRole: ChannelRole.owner,
      );

      final bloc = ChannelDetailBloc(repository: repository, channelId: channelId);
      bloc.add(const ChannelDetailLoaded(channelId));
      await pumpEventQueue();

      expect(repository.listPendingRequestsCallCount, 1);
      expect(bloc.state.isLoading, false);
      expect(bloc.state.detail?.name, 'Kênh Owner');
      expect(bloc.state.pendingRequests.length, 1);
      expect(bloc.state.pendingRequests.first.requestId, 'req_1');
      await bloc.close();
    });

    test('Owner mở detail nhưng listPendingRequests lỗi 403: fallback rỗng, không sập màn hình', () async {
      repository.detailToReturn = const ChannelDetailModel(
        channelId: channelId,
        name: 'Kênh Owner Gặp Lỗi API',
        myRole: ChannelRole.owner,
      );
      repository.shouldThrowOnListPending = true;

      final bloc = ChannelDetailBloc(repository: repository, channelId: channelId);
      bloc.add(const ChannelDetailLoaded(channelId));
      await pumpEventQueue();

      expect(repository.listPendingRequestsCallCount, 1);
      expect(bloc.state.isLoading, false);
      expect(bloc.state.detail?.name, 'Kênh Owner Gặp Lỗi API');
      expect(bloc.state.members.length, 1);
      expect(bloc.state.pendingRequests, isEmpty);
      await bloc.close();
    });
  });
}
