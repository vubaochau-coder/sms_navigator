import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/channel_detail_model.dart';
import 'package:sms_navigator/core/models/channel_member_model.dart';
import 'package:sms_navigator/core/models/channel_model.dart';
import 'package:sms_navigator/core/models/pairing_request_model.dart';
import 'package:sms_navigator/core/models/pairing_session_model.dart';
import 'package:sms_navigator/core/models/whitelist_config_model.dart';
import 'package:sms_navigator/core/repositories/channel_repository.dart';
import 'package:sms_navigator/core/repositories/whitelist_repository.dart';
import 'package:sms_navigator/core/services/channel_key_store.dart';
import 'package:sms_navigator/core/utils/channel_crypto_helper.dart';
import 'package:sms_navigator/features/settings/bloc/whitelist_bloc.dart';
import 'package:sms_navigator/features/settings/bloc/whitelist_event.dart';

class _FakeWhitelistRepository implements WhitelistRepository {
  WhitelistConfigModel stored = const WhitelistConfigModel();
  bool shouldFailSave = false;
  bool shouldFailLoad = false;
  int saveCallCount = 0;

  @override
  Future<WhitelistConfigModel> getWhitelist(String channelId) async {
    if (shouldFailLoad) {
      throw Exception('native error');
    }
    return stored;
  }

  @override
  Future<bool> saveWhitelist({
    required String channelId,
    required WhitelistConfigModel config,
    required int keyEpoch,
    required String channelKeyBase64,
  }) async {
    saveCallCount++;
    if (shouldFailSave) return false;
    stored = config;
    return true;
  }

  @override
  Future<WhitelistConfigModel?> syncWhitelistFromServer({
    required String channelId,
    required int keyEpoch,
    required String channelKeyBase64,
    required ChannelWhitelistBlobModel blob,
  }) async => stored;

  @override
  Future<List<Map<String, dynamic>>> getRecentLogs() async => const [];
}

class _FakeChannelRepository implements ChannelRepository {
  @override
  Future<ChannelDetailModel> getChannelDetail(String channelId) async {
    return const ChannelDetailModel(
      channelId: 'ch_1',
      name: 'Channel 1',
      myRole: ChannelRole.owner,
      status: 'ACTIVE',
      currentEpoch: 1,
      myStatus: 'ACTIVE',
    );
  }

  @override
  Future<List<ChannelModel>> listChannels() async => [];
  @override
  Future<List<ChannelMemberModel>> getMembers(String channelId) async => [];
  @override
  Future<List<PairingRequestModel>> listPendingRequests(String channelId) async => [];
  @override
  Future<ChannelModel> createChannel(String name) async => throw UnimplementedError();
  @override
  Future<int> approveRequest({required String channelId, required PairingRequestModel request}) async => 1;
  @override
  Future<void> rejectRequest(String requestId) async {}
  @override
  Future<int> revokeMembers({required String channelId, required List<String> revokeDeviceIds}) async => 1;
  @override
  Future<PairingSessionModel> createPairingSession(String channelId) async => throw UnimplementedError();
  @override
  Future<int?> provisionLatestChannelKey({required String channelId, required String ownerPublicKeyBase64}) async => null;
  @override
  Future<void> renameDevice(String deviceName) async {}
}

class _FakeChannelKeyStore implements ChannelKeyStore {
  @override
  Future<String?> getChannelKey({required String channelId, required int epoch}) async {
    return base64Encode(List.filled(32, 1));
  }

  @override
  Future<void> saveChannelKey({required String channelId, required int epoch, required String channelKeyBase64}) async {}
  @override
  Future<IdentityKeyPair> getOrCreateIdentityKeyPair() async => throw UnimplementedError();
  @override
  Future<IdentityKeyPair?> loadIdentityKeyPair() async => null;
  @override
  Future<List<int>> listProvisionedEpochs(String channelId) async => [1];
  @override
  Future<void> purgeChannelKeys(String channelId) async {}
}

void main() {
  late _FakeWhitelistRepository repository;
  late _FakeChannelRepository channelRepository;
  late _FakeChannelKeyStore keyStore;
  late WhitelistBloc bloc;

  setUp(() {
    repository = _FakeWhitelistRepository();
    channelRepository = _FakeChannelRepository();
    keyStore = _FakeChannelKeyStore();
    bloc = WhitelistBloc(
      channelId: 'ch_1',
      repository: repository,
      channelRepository: channelRepository,
      keyStore: keyStore,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('WhitelistStarted', () {
    test('loads config from native', () async {
      repository.stored = const WhitelistConfigModel(
        mode: WhitelistMode.allAddresses,
        entries: [WhitelistEntryModel(address: 'VCB', allowOtp: true)],
      );

      bloc.add(const WhitelistStarted());
      await bloc.close();

      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.config.mode, WhitelistMode.allAddresses);
      expect(bloc.state.config.entries.first.address, 'VCB');
    });

    test('keeps default config when load fails', () async {
      repository.shouldFailLoad = true;

      bloc.add(const WhitelistStarted());
      await bloc.close();

      expect(bloc.state.isLoading, isFalse);
      expect(bloc.state.config, const WhitelistConfigModel());
    });

    test('empty explicit config marks blocksEverything', () async {
      bloc.add(const WhitelistStarted());
      await bloc.close();

      expect(bloc.state.blocksEverything, isTrue);
    });
  });

  group('WhitelistEntryAdded', () {
    test('adds entry with allowOtp default false and persists', () async {
      bloc.add(const WhitelistStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const WhitelistEntryAdded(address: 'VCB'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.config.entries.length, 1);
      expect(bloc.state.config.entries.first.allowOtp, isFalse);
      expect(repository.saveCallCount, 1);
      expect(repository.stored.entries.first.address, 'VCB');
    });

    test('rejects blank address without persisting', () async {
      bloc.add(const WhitelistStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const WhitelistEntryAdded(address: '   '));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.config.entries, isEmpty);
      expect(repository.saveCallCount, 0);
    });

    test('rejects exact duplicate address', () async {
      bloc.add(const WhitelistStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const WhitelistEntryAdded(address: 'VCB'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const WhitelistEntryAdded(address: 'VCB'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.config.entries.length, 1);
      expect(repository.saveCallCount, 1);
    });

    test('different case address is a distinct entry (case-sensitive)', () async {
      bloc.add(const WhitelistStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const WhitelistEntryAdded(address: 'VCB'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const WhitelistEntryAdded(address: 'vcb'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.config.entries.length, 2);
      expect(repository.saveCallCount, 2);
      expect(
        bloc.state.config.entries.map((entry) => entry.address),
        containsAll(['VCB', 'vcb']),
      );
    });
  });

  group('WhitelistAllowOtpToggled', () {
    test('toggles allowOtp on matching entry only', () async {
      bloc.add(const WhitelistStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const WhitelistEntryAdded(address: 'VCB'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(const WhitelistEntryAdded(address: 'MOMO'));
      await Future<void>.delayed(Duration.zero);
      bloc.add(WhitelistAllowOtpToggled(bloc.state.config.entries.first));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.config.entries[0].allowOtp, isTrue);
      expect(bloc.state.config.entries[1].allowOtp, isFalse);
      expect(repository.saveCallCount, 3);
    });
  });

  group('WhitelistEntryRemoved', () {
    test('removes matching entry', () async {
      bloc.add(const WhitelistStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const WhitelistEntryAdded(address: 'VCB'));
      await Future<void>.delayed(Duration.zero);
      final entry = bloc.state.config.entries.first;
      bloc.add(WhitelistEntryRemoved(entry));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.config.entries, isEmpty);
      expect(bloc.state.blocksEverything, isTrue);
    });
  });

  group('WhitelistModeChanged', () {
    test('switches mode and persists', () async {
      bloc.add(const WhitelistStarted());
      await Future<void>.delayed(Duration.zero);
      bloc.add(const WhitelistModeChanged(WhitelistMode.allAddresses));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.config.mode, WhitelistMode.allAddresses);
      expect(repository.stored.mode, WhitelistMode.allAddresses);
    });

    test('save failure keeps old config', () async {
      bloc.add(const WhitelistStarted());
      await Future<void>.delayed(Duration.zero);
      repository.shouldFailSave = true;
      bloc.add(const WhitelistEntryAdded(address: 'VCB'));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.config.entries, isEmpty);
      expect(bloc.state.isLoading, isFalse);
    });
  });
}
