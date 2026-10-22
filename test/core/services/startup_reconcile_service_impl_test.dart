import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/models/channel_detail_model.dart';
import 'package:sms_navigator/core/models/whitelist_config_model.dart';
import 'package:sms_navigator/core/crypto/channel_crypto_helper.dart';
import 'package:sms_navigator/core/models/channel_model.dart';
import 'package:sms_navigator/core/models/pairing_request_model.dart';
import 'package:sms_navigator/core/repositories/channel_repository.dart';
import 'package:sms_navigator/core/repositories/join_channel_repository.dart';
import 'package:sms_navigator/core/services/channel_key_store.dart';
import 'package:sms_navigator/core/services/device_api_service.dart';
import 'package:sms_navigator/core/services/device_storage_service.dart';
import 'package:sms_navigator/core/services/impls/startup_reconcile_service_impl.dart';

class _Channels implements ChannelRepository {
  List<ChannelModel> channels = [];
  int detailCalls = 0;

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

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getChannelDetail) detailCalls++;
    throw UnimplementedError('${invocation.memberName}');
  }
}

class _Join implements JoinChannelRepository {
  List<PairingRequestModel> mine = [];
  final List<String> provisioned = [];
  Set<String> failFor = {};

  @override
  Future<List<PairingRequestModel>> listMyRequests() async => mine;

  @override
  Future<int?> provisionLatestForApproved({required String channelId}) async {
    provisioned.add(channelId);
    if (failFor.contains(channelId)) throw StateError('offline');
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class _Keys implements ChannelKeyStore {
  final Map<String, String> keys = {};

  @override
  Future<IdentityKeyPair> getOrCreateIdentityKeyPair() async =>
      const IdentityKeyPair(privateKeyBase64: 'p', publicKeyBase64: 'q');

  @override
  Future<String?> getChannelKey({required String channelId, required int epoch}) async =>
      keys['$channelId#$epoch'];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class _Storage implements DeviceStorageService {
  @override
  Future<String?> getDeviceToken() async => 'token';

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class _DeviceApi implements DeviceApiService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

ChannelModel _channel(String id, int epoch, {ChannelRole role = ChannelRole.member}) =>
    ChannelModel(channelId: id, name: id, role: role, currentEpoch: epoch);

void main() {
  late _Channels channels;
  late _Join join;
  late _Keys keys;
  late StartupReconcileServiceImpl reconcile;

  setUp(() {
    channels = _Channels();
    join = _Join();
    keys = _Keys();
    reconcile = StartupReconcileServiceImpl(
      deviceApiService: _DeviceApi(),
      deviceStorage: _Storage(),
      keyStore: keys,
      channelRepository: channels,
      joinRepository: join,
      deviceNameProvider: () => 'Phone',
    );
  });

  test('channels that already hold the key for current_epoch cost no request', () async {
    channels.channels = [
      _channel('a', 3, role: ChannelRole.owner),
      _channel('b', 2),
      _channel('c', 5),
    ];
    keys.keys['a#3'] = 'ka';
    keys.keys['b#2'] = 'kb';
    keys.keys['c#4'] = 'old'; // c rotated to 5 → still needs provisioning

    await reconcile.reconcile();

    expect(join.provisioned, ['c']);
    expect(channels.detailCalls, 0);
  });

  test('channels provisioned from approved requests are not provisioned twice', () async {
    join.mine = const [
      PairingRequestModel(requestId: 'r1', channelId: 'x', status: PairingRequestStatus.approved),
      PairingRequestModel(requestId: 'r2', channelId: 'y', status: PairingRequestStatus.pending),
    ];
    channels.channels = [_channel('x', 2), _channel('z', 1)];

    await reconcile.reconcile();

    expect(join.provisioned, ['x', 'z']);
  });

  test('one failing channel does not stop the others', () async {
    channels.channels = [_channel('a', 1), _channel('b', 1), _channel('c', 1)];
    join.failFor = {'b'};

    await reconcile.reconcile();

    expect(join.provisioned..sort(), ['a', 'b', 'c']);
  });
}
