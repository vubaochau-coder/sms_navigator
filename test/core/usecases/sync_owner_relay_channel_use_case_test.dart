import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/whitelist_config_model.dart';
import 'package:sms_navigator/core/models/request_history_result.dart';
import 'package:sms_navigator/core/models/channel_detail_model.dart';
import 'package:sms_navigator/core/models/channel_member_model.dart';
import 'package:sms_navigator/core/models/channel_model.dart';
import 'package:sms_navigator/core/models/pairing_request_model.dart';
import 'package:sms_navigator/core/models/pairing_session_model.dart';
import 'package:sms_navigator/core/repositories/channel_repository.dart';
import 'package:sms_navigator/core/services/channel_key_store.dart';
import 'package:sms_navigator/core/services/device_storage_service.dart';
import 'package:sms_navigator/core/services/relay_channel_bridge.dart';
import 'package:sms_navigator/core/usecases/sync_owner_relay_channel_use_case.dart';
import 'package:sms_navigator/core/usecases/sync_channel_keys_use_case.dart';
import 'package:sms_navigator/core/crypto/channel_crypto_helper.dart';

class FakeChannelRepository implements ChannelRepository {
  List<ChannelModel> channels = [];

  /// Key the fake "server self-envelope" yields on provisionLatestChannelKey.
  FakeChannelKeyStore? recoverInto;
  int? recoverEpoch;
  String recoverKey = 'recovered-key';
  final List<String> provisionCalls = [];

  /// Channels whose detail reports `rotation_pending`; rotating saves `rotated-<id>` at epoch+1.
  final Set<String> rotationPending = {};
  final List<String> rotateCalls = [];
  Object? rotateError;

  @override
  Future<List<ChannelModel>> listChannelsWithWhitelist() => listChannels();

  @override
  Future<WhitelistConfigModel?> readWhitelist({
    required String channelId,
    required bool isOwner,
    ChannelWhitelistBlobModel? blob,
  }) async => null;

  @override
  Future<List<ChannelModel>> listChannels() async => channels;

  int detailCalls = 0;

  @override
  Future<ChannelDetailModel> getChannelDetail(String channelId) async {
    detailCalls++;
    return _detail(channelId);
  }

  ChannelDetailModel _detail(String channelId) =>
      ChannelDetailModel(
        channelId: channelId,
        name: 'detail-$channelId',
        ownerPublicKey: 'owner-pk',
        myRole: ChannelRole.owner,
        rotationPending: rotationPending.contains(channelId),
      );

  @override
  Future<List<ChannelMemberModel>> getMembers(String channelId) async => [];

  @override
  Future<List<PairingRequestModel>> listPendingRequests(String channelId) async => [];

  @override
  Future<ChannelModel> createChannel(String name) async =>
      throw UnimplementedError();

  @override
  Future<int> approveRequest({
    required String channelId,
    required PairingRequestModel request,
  }) async => 2;

  @override
  Future<void> rejectRequest(String requestId) async {}

  @override
  Future<int> revokeMembers({
    required String channelId,
    required List<String> revokeDeviceIds,
  }) async => 2;

  @override
  Future<PairingSessionModel> createPairingSession(String channelId) async =>
      throw UnimplementedError();

  @override
  Future<int?> provisionLatestChannelKey({
    required String channelId,
    required String ownerPublicKeyBase64,
  }) async {
    provisionCalls.add('$channelId|$ownerPublicKeyBase64');
    final epoch = recoverEpoch;
    if (epoch == null || recoverInto == null) return null;
    await recoverInto!.saveChannelKey(
      channelId: channelId,
      epoch: epoch,
      channelKeyBase64: recoverKey,
    );
    return epoch;
  }

  @override
  Future<void> renameDevice(String newName) async {}

  @override
  Future<void> renameChannel({required String channelId, required String name}) async {}

  @override
  Future<RequestHistoryResult> listRequestHistory(String channelId, {String? before}) async =>
      const RequestHistoryResult();

  @override
  Future<void> leaveChannel(String channelId) async {}

  @override
  Future<void> archiveChannel(String channelId) async {}

  @override
  Future<int> rotateChannelKey(String channelId) async {
    rotateCalls.add(channelId);
    if (rotateError != null) throw rotateError!;
    final epoch = channels.firstWhere((c) => c.channelId == channelId).currentEpoch + 1;
    recoverInto?.keys['${channelId}_$epoch'] = 'rotated-$channelId';
    rotationPending.remove(channelId);
    return epoch;
  }
}

class FakeChannelKeyStore implements ChannelKeyStore {
  final Map<String, String> keys = {};

  @override
  Future<String?> getChannelKey({
    required String channelId,
    required int epoch,
  }) async => keys['${channelId}_$epoch'];

  @override
  Future<void> saveChannelKey({
    required String channelId,
    required int epoch,
    required String channelKeyBase64,
  }) async {
    keys['${channelId}_$epoch'] = channelKeyBase64;
  }

  @override
  Future<IdentityKeyPair> getOrCreateIdentityKeyPair() async =>
      throw UnimplementedError();

  @override
  Future<IdentityKeyPair?> loadIdentityKeyPair() async => null;

  @override
  Future<List<int>> listProvisionedEpochs(String channelId) async => [1];

  @override
  Future<void> purgeChannelKeys(String channelId) async {
    keys.clear();
  }
}

class FakeDeviceStorageService implements DeviceStorageService {
  String? token = 'token-abc';
  String? serverUrl = 'https://sms-navigator-server.onrender.com';

  @override
  Future<String?> getDeviceId() async => 'device-123';
  @override
  Future<void> saveDeviceId(String deviceId) async {}
  @override
  Future<String?> getDeviceName() async => 'My Device';
  @override
  Future<void> saveDeviceName(String deviceName) async {}
  @override
  Future<String?> getDeviceToken() async => token;
  @override
  Future<void> saveDeviceToken(String deviceToken) async => token = deviceToken;
  @override
  Future<void> clearDeviceToken() async => token = null;
  @override
  Future<String?> getServerUrl() async => serverUrl;
  @override
  Future<void> saveServerUrl(String url) async => serverUrl = url;
  @override
  Future<String?> getFcmToken() async => null;
  @override
  Future<void> saveFcmToken(String fcmToken) async {}
  @override
  Future<void> clearAll() async {}
}

class FakeRelayBridge implements RelayChannelBridge {
  List<RelayChannelSnapshot>? replaced;
  List<String> retained = const [];
  String? token;
  String? baseUrl;
  int flushCalls = 0;
  int parkedToFlush = 0;

  @override
  Future<void> setCredentials({required String deviceToken, String? apiBaseUrl}) async {
    token = deviceToken;
    baseUrl = apiBaseUrl;
  }

  @override
  Future<int> replaceRelayChannels(
    List<RelayChannelSnapshot> channels, {
    List<String> retainChannelIds = const [],
  }) async {
    replaced = channels;
    retained = retainChannelIds;
    return channels.length;
  }

  @override
  Future<void> stageKey({
    required String channelId,
    required int keyEpoch,
    required String channelKeyBase64,
    String? channelName,
  }) async {}

  @override
  Future<bool> promoteKey({required String channelId, required int keyEpoch}) async => true;

  @override
  Future<void> discardKey({required String channelId, required int keyEpoch}) async {}

  @override
  Future<int> flushParkedMessages() async {
    flushCalls++;
    return parkedToFlush;
  }
}

class FakeKeySync implements SyncChannelKeysUseCase {
  FakeKeySync(this.keyStore);
  final FakeChannelKeyStore keyStore;
  final Map<String, String> provides = {};
  final List<String?> calls = [];

  @override
  Future<ChannelKeySyncResult> call({String? channelId}) async {
    calls.add(channelId);
    keyStore.keys.addAll(provides);
    return ChannelKeySyncResult(added: provides.length);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late FakeChannelRepository channelRepo;
  late FakeChannelKeyStore keyStore;
  late FakeDeviceStorageService deviceStorage;
  late FakeRelayBridge bridge;
  late SyncOwnerRelayChannelUseCase useCase;

  ChannelModel owner(String id, {int epoch = 1, String status = 'ACTIVE'}) => ChannelModel(
        channelId: id,
        name: 'Kênh $id',
        role: ChannelRole.owner,
        currentEpoch: epoch,
        status: status,
      );

  setUp(() {
    channelRepo = FakeChannelRepository();
    keyStore = FakeChannelKeyStore();
    deviceStorage = FakeDeviceStorageService();
    bridge = FakeRelayBridge();
    useCase = SyncOwnerRelayChannelUseCase(
      channelRepository: channelRepo,
      keyStore: keyStore,
      deviceStorage: deviceStorage,
      relayBridge: bridge,
    );
  });

  test('clears native relay when user owns no active channels', () async {
    channelRepo.channels = [
      const ChannelModel(
        channelId: 'ch-member',
        name: 'Member Channel',
        role: ChannelRole.member,
        status: 'ACTIVE',
      ),
    ];

    final result = await useCase();
    expect(result, isFalse);
    expect(bridge.replaced, isEmpty);
    expect(bridge.retained, isEmpty);
  });

  test('syncs EVERY active owner channel, not only the first', () async {
    channelRepo.channels = [
      owner('ch-a', epoch: 2),
      owner('ch-b', epoch: 5),
      owner('ch-archived', status: 'ARCHIVED'),
    ];
    keyStore.keys['ch-a_2'] = 'key-a-2';
    keyStore.keys['ch-b_5'] = 'key-b-5';

    final result = await useCase();

    expect(result, isTrue);
    expect(bridge.replaced, const [
      RelayChannelSnapshot(channelId: 'ch-a', channelName: 'Kênh ch-a', keyEpoch: 2, channelKeyBase64: 'key-a-2'),
      RelayChannelSnapshot(channelId: 'ch-b', channelName: 'Kênh ch-b', keyEpoch: 5, channelKeyBase64: 'key-b-5'),
    ]);
    expect(bridge.token, 'token-abc');
    expect(bridge.baseUrl, deviceStorage.serverUrl);
  });

  test('uses expectedEpoch hint only for the channel it targets', () async {
    channelRepo.channels = [owner('ch-a', epoch: 1), owner('ch-b', epoch: 1)];
    keyStore.keys['ch-a_2'] = 'key-a-rotated';
    keyStore.keys['ch-b_1'] = 'key-b-1';

    await useCase(channelId: 'ch-a', expectedEpoch: 2);

    final byId = {for (final s in bridge.replaced!) s.channelId: s};
    expect(byId['ch-a']!.keyEpoch, 2);
    expect(byId['ch-a']!.channelKeyBase64, 'key-a-rotated');
    expect(byId['ch-b']!.keyEpoch, 1);
  });

  test('recovers a missing key from the owner self-envelope', () async {
    channelRepo.channels = [owner('ch-a', epoch: 3)];
    channelRepo.recoverInto = keyStore;
    channelRepo.recoverEpoch = 3;

    final result = await useCase();

    expect(result, isTrue);
    expect(channelRepo.provisionCalls, ['ch-a|owner-pk']);
    expect(bridge.replaced!.single.channelKeyBase64, 'recovered-key');
    expect(bridge.replaced!.single.keyEpoch, 3);
  });

  test('retains a channel on native when its key cannot be resolved', () async {
    channelRepo.channels = [owner('ch-a', epoch: 3), owner('ch-b', epoch: 1)];
    keyStore.keys['ch-b_1'] = 'key-b-1';

    await useCase();

    expect(bridge.replaced!.map((s) => s.channelId), ['ch-b']);
    expect(bridge.retained, ['ch-a']);
  });

  test('rotates a channel a member left (rotation_pending) and relays on the new epoch', () async {
    channelRepo.channels = [owner('ch-a', epoch: 3), owner('ch-b', epoch: 1)];
    channelRepo.rotationPending.add('ch-a');
    channelRepo.recoverInto = keyStore;
    keyStore.keys['ch-a_3'] = 'key-a-3';
    keyStore.keys['ch-b_1'] = 'key-b-1';

    await useCase();

    expect(channelRepo.rotateCalls, ['ch-a']);
    expect(bridge.replaced, const [
      RelayChannelSnapshot(channelId: 'ch-a', channelName: 'Kênh ch-a', keyEpoch: 4, channelKeyBase64: 'rotated-ch-a'),
      RelayChannelSnapshot(channelId: 'ch-b', channelName: 'Kênh ch-b', keyEpoch: 1, channelKeyBase64: 'key-b-1'),
    ]);
  });

  test('a failed pending rotation keeps relaying on the current epoch', () async {
    channelRepo.channels = [owner('ch-a', epoch: 3)];
    channelRepo.rotationPending.add('ch-a');
    channelRepo.rotateError = Exception('offline');
    keyStore.keys['ch-a_3'] = 'key-a-3';

    await useCase();

    expect(channelRepo.rotateCalls, ['ch-a']);
    expect(bridge.replaced!.single.keyEpoch, 3);
  });

  test('does nothing without a device token', () async {
    deviceStorage.token = null;
    channelRepo.channels = [owner('ch-a')];
    keyStore.keys['ch-a_1'] = 'key';

    final result = await useCase();

    expect(result, isFalse);
    expect(bridge.replaced, isNull);
  });

  test('flushes parked SMS after syncing keys', () async {
    channelRepo.channels = [owner('ch-a')];
    keyStore.keys['ch-a_1'] = 'key';
    bridge.parkedToFlush = 2;

    await useCase();

    expect(bridge.flushCalls, 1);
  });

  group('FLOW_AUDIT P1/P2 — fewer requests', () {
    ChannelModel listed(String id, {int epoch = 1, bool pending = false}) => ChannelModel(
      channelId: id,
      name: 'Kênh $id',
      role: ChannelRole.owner,
      status: 'ACTIVE',
      currentEpoch: epoch,
      rotationPending: pending,
    );

    test('list with relay metadata → no GET /channels/detail at all', () async {
      channelRepo.channels = [listed('ch-a', epoch: 2), listed('ch-b')];
      keyStore.keys['ch-a_2'] = 'key-a-2';
      keyStore.keys['ch-b_1'] = 'key-b-1';

      await useCase();

      expect(channelRepo.detailCalls, 0);
      expect(bridge.replaced, hasLength(2));
    });

    test('rotation_pending from the list still triggers the rotation', () async {
      channelRepo.channels = [listed('ch-a', epoch: 3, pending: true)];
      channelRepo.recoverInto = keyStore;
      keyStore.keys['ch-a_3'] = 'key-a-3';

      await useCase();

      expect(channelRepo.rotateCalls, ['ch-a']);
      expect(bridge.replaced!.single.keyEpoch, 4);
      expect(channelRepo.detailCalls, 0);
    });

    test('missing owner key → one key sync for that channel, no detail', () async {
      final keySync = FakeKeySync(keyStore)..provides['ch-a_3'] = 'synced-a-3';
      final withSync = SyncOwnerRelayChannelUseCase(
        channelRepository: channelRepo,
        keyStore: keyStore,
        deviceStorage: deviceStorage,
        relayBridge: bridge,
        syncChannelKeys: keySync,
      );
      channelRepo.channels = [listed('ch-a', epoch: 3)];

      await withSync();

      expect(keySync.calls, ['ch-a']);
      expect(bridge.replaced!.single.channelKeyBase64, 'synced-a-3');
      expect(channelRepo.provisionCalls, isEmpty);
      expect(channelRepo.detailCalls, 0);
    });

    test('untargeted calls right after each other share one run; targeted calls always run', () async {
      channelRepo.channels = [listed('ch-a')];
      keyStore.keys['ch-a_1'] = 'key-a-1';
      var listCalls = 0;
      final counting = _CountingRepo(channelRepo, () => listCalls++);
      final shared = SyncOwnerRelayChannelUseCase(
        channelRepository: counting,
        keyStore: keyStore,
        deviceStorage: deviceStorage,
        relayBridge: bridge,
      );

      await Future.wait([shared(), shared()]);
      await shared();
      expect(listCalls, 1);

      await shared(channelId: 'ch-a', expectedEpoch: 1);
      expect(listCalls, 2);
    });
  });
}

/// Đếm `listChannels`, uỷ quyền phần còn lại cho [FakeChannelRepository].
class _CountingRepo extends FakeChannelRepository {
  _CountingRepo(this.inner, this.onList);
  final FakeChannelRepository inner;
  final void Function() onList;

  @override
  Future<List<ChannelModel>> listChannels() {
    onList();
    return inner.listChannels();
  }
}
