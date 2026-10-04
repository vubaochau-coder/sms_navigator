import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/channel_model.dart';
import 'package:sms_navigator/core/repositories/channel_repository.dart';
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

void main() {
  late _FakeChannelRepository repository;
  late ChannelBloc bloc;

  setUp(() {
    repository = _FakeChannelRepository();
    bloc = ChannelBloc(repository: repository);
  });

  tearDown(() {
    bloc.close();
  });

  group('ChannelBloc - ChannelListLoaded', () {
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

      bloc.add(const ChannelListLoaded());
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

      bloc.add(const ChannelListLoaded());
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
}
