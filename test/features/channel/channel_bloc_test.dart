import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/channel_model.dart';
import 'package:sms_navigator/core/models/pairing_request_model.dart';
import 'package:sms_navigator/core/repositories/channel_repository.dart';
import 'package:sms_navigator/core/repositories/join_channel_repository.dart';
import 'package:sms_navigator/features/channel/bloc/channel_bloc.dart';

class _FakeChannelRepository implements ChannelRepository {
  List<ChannelModel> channels = [];
  bool failList = false;
  bool failCreate = false;
  bool failRename = false;
  String? lastCreatedName;
  String? lastRenamedDevice;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<ChannelModel>> listChannels() async {
    if (failList) throw Exception('Network error');
    return channels;
  }

  @override
  Future<ChannelModel> createChannel(String name) async {
    if (failCreate) throw Exception('Create error');
    lastCreatedName = name;
    final created = ChannelModel(
      channelId: 'ch-new',
      name: name,
      role: ChannelRole.owner,
      memberCount: 1,
    );
    channels.add(created);
    return created;
  }

  @override
  Future<void> renameDevice(String newName) async {
    if (failRename) throw Exception('Rename error');
    lastRenamedDevice = newName;
  }
}

class _FakeJoinChannelRepository implements JoinChannelRepository {
  List<PairingRequestModel> requests = [];
  bool failList = false;
  bool failCancel = false;
  String? lastCancelledRequestId;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<PairingRequestModel>> listMyRequests() async {
    if (failList) throw Exception('Network error');
    return requests;
  }

  @override
  Future<void> cancelRequest(String requestId) async {
    if (failCancel) throw Exception('Cancel error');
    lastCancelledRequestId = requestId;
    requests = requests.where((r) => r.requestId != requestId).toList();
  }
}

void main() {
  late _FakeChannelRepository repository;
  late _FakeJoinChannelRepository joinRepository;
  late ChannelBloc bloc;

  setUp(() {
    repository = _FakeChannelRepository();
    joinRepository = _FakeJoinChannelRepository();
    bloc = ChannelBloc(
      repository: repository,
      joinRepository: joinRepository,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('ChannelBloc - ChannelLoadDataEvent', () {
    test('loads owned and joined channels correctly', () async {
      repository.channels = [
        const ChannelModel(
          channelId: 'c1',
          name: 'My Owner Channel',
          role: ChannelRole.owner,
          memberCount: 2,
        ),
        const ChannelModel(
          channelId: 'c2',
          name: 'Joined Channel',
          role: ChannelRole.member,
          memberCount: 5,
        ),
      ];

      bloc.add(const ChannelLoadDataEvent());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.errorMessage, isNull);
      expect(bloc.state.ownedChannels.length, 1);
      expect(bloc.state.ownedChannels.first.name, 'My Owner Channel');
      expect(bloc.state.joinedChannels.length, 1);
      expect(bloc.state.joinedChannels.first.name, 'Joined Channel');
      expect(bloc.state.isEmpty, isFalse);
    });

    test('emits error message when loading fails', () async {
      repository.failList = true;

      bloc.add(const ChannelLoadDataEvent());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.errorMessage, isNotNull);
      expect(bloc.state.ownedChannels, isEmpty);
      expect(bloc.state.joinedChannels, isEmpty);
    });
  });

  group('ChannelBloc - ChannelCreated', () {
    test('creates channel and refreshes list', () async {
      bloc.add(const ChannelCreated('Finance OTP'));
      await Future<void>.delayed(Duration.zero);

      expect(repository.lastCreatedName, 'Finance OTP');
      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.ownedChannels.length, 1);
      expect(bloc.state.ownedChannels.first.name, 'Finance OTP');
    });

    test('emits error on creation failure', () async {
      repository.failCreate = true;

      bloc.add(const ChannelCreated('Broken Channel'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.errorMessage, isNotNull);
    });
  });

  group('ChannelBloc - DeviceRenamed', () {
    test('renames device successfully', () async {
      bloc.add(const DeviceRenamed('Pixel 9 Pro'));
      await Future<void>.delayed(Duration.zero);

      expect(repository.lastRenamedDevice, 'Pixel 9 Pro');
      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.errorMessage, isNull);
    });

    test('emits error on rename failure', () async {
      repository.failRename = true;

      bloc.add(const DeviceRenamed('Failed Device'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.errorMessage, isNotNull);
    });
  });

  group('ChannelBloc - Pending Join Requests', () {
    test('loads pending join requests and filters out non-pending', () async {
      joinRepository.requests = const [
        PairingRequestModel(
          requestId: 'req-1',
          channelName: 'Channel A',
          status: PairingRequestStatus.pending,
        ),
        PairingRequestModel(
          requestId: 'req-2',
          channelName: 'Channel B',
          status: PairingRequestStatus.approved,
        ),
        PairingRequestModel(
          requestId: 'req-3',
          channelName: 'Channel C',
          status: PairingRequestStatus.cancelled,
        ),
      ];

      bloc.add(const ChannelLoadDataEvent());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.pendingJoinRequests.length, 1);
      expect(bloc.state.pendingJoinRequests.first.requestId, 'req-1');
      expect(bloc.state.pendingJoinRequests.first.channelName, 'Channel A');
    });

    test('retains channel list even when joinRepository throws', () async {
      repository.channels = const [
        ChannelModel(
          channelId: 'c1',
          name: 'Owner Ch',
          role: ChannelRole.owner,
        ),
      ];
      joinRepository.failList = true;

      bloc.add(const ChannelLoadDataEvent());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.ownedChannels.length, 1);
      expect(bloc.state.pendingJoinRequests, isEmpty);
    });

    test('cancels pending join request successfully', () async {
      joinRepository.requests = const [
        PairingRequestModel(
          requestId: 'req-1',
          channelName: 'Channel A',
          status: PairingRequestStatus.pending,
        ),
        PairingRequestModel(
          requestId: 'req-2',
          channelName: 'Channel B',
          status: PairingRequestStatus.pending,
        ),
      ];

      bloc.add(const ChannelLoadDataEvent());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.pendingJoinRequests.length, 2);

      bloc.add(const ChannelPendingJoinCancelled('req-1'));
      await Future<void>.delayed(Duration.zero);

      expect(joinRepository.lastCancelledRequestId, 'req-1');
      expect(bloc.state.pendingJoinRequests.length, 1);
      expect(bloc.state.pendingJoinRequests.first.requestId, 'req-2');
    });

    test('handles cancel failure without crashing', () async {
      joinRepository.requests = const [
        PairingRequestModel(
          requestId: 'req-1',
          channelName: 'Channel A',
          status: PairingRequestStatus.pending,
        ),
      ];

      bloc.add(const ChannelLoadDataEvent());
      await Future<void>.delayed(Duration.zero);

      joinRepository.failCancel = true;
      bloc.add(const ChannelPendingJoinCancelled('req-1'));
      await Future<void>.delayed(Duration.zero);

      // Request still remains in pending list on failure
      expect(bloc.state.pendingJoinRequests.length, 1);
    });
  });
}
