import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/errors/app_exceptions.dart';
import 'package:sms_navigator/core/models/channel_detail_model.dart';
import 'package:sms_navigator/core/models/channel_member_model.dart';
import 'package:sms_navigator/core/models/channel_model.dart';
import 'package:sms_navigator/core/models/pairing_request_model.dart';
import 'package:sms_navigator/core/repositories/impls/channel_repository_impl.dart';
import 'package:sms_navigator/core/services/channel_api_service.dart';
import 'package:sms_navigator/core/services/channel_key_store.dart';
import 'package:sms_navigator/core/services/device_api_service.dart';
import 'package:sms_navigator/core/services/device_storage_service.dart';
import 'package:sms_navigator/core/services/pairing_api_service.dart';
import 'package:sms_navigator/core/services/relay_channel_bridge.dart';
import 'package:sms_navigator/core/crypto/channel_crypto_helper.dart';

/// Records the order of side effects across key store, native bridge and server.
final List<String> _events = [];

class _KeyStore implements ChannelKeyStore {
  _KeyStore(this.identity);
  final IdentityKeyPair identity;
  final Map<String, String> keys = {};

  @override
  Future<IdentityKeyPair?> loadIdentityKeyPair() async => identity;
  @override
  Future<IdentityKeyPair> getOrCreateIdentityKeyPair() async => identity;
  @override
  Future<String?> getChannelKey({required String channelId, required int epoch}) async =>
      keys['$channelId#$epoch'];
  @override
  Future<void> saveChannelKey({
    required String channelId,
    required int epoch,
    required String channelKeyBase64,
  }) async {
    _events.add('keystore.save:$epoch');
    keys['$channelId#$epoch'] = channelKeyBase64;
  }

  @override
  Future<List<int>> listProvisionedEpochs(String channelId) async => const [];
  @override
  Future<void> purgeChannelKeys(String channelId) async {}
}

class _Bridge implements RelayChannelBridge {
  @override
  Future<void> stageKey({
    required String channelId,
    required int keyEpoch,
    required String channelKeyBase64,
    String? channelName,
  }) async => _events.add('native.stage:$keyEpoch');
  @override
  Future<bool> promoteKey({required String channelId, required int keyEpoch}) async {
    _events.add('native.promote:$keyEpoch');
    return true;
  }

  @override
  Future<void> discardKey({required String channelId, required int keyEpoch}) async =>
      _events.add('native.discard:$keyEpoch');
  @override
  Future<void> setCredentials({required String deviceToken, String? apiBaseUrl}) async {}
  @override
  Future<int> replaceRelayChannels(
    List<RelayChannelSnapshot> channels, {
    List<String> retainChannelIds = const [],
  }) async => channels.length;
  @override
  Future<int> flushParkedMessages() async => 0;
}

class _ChannelApi implements ChannelApiService {
  _ChannelApi(this.ownerId, this.ownerPk);
  final String ownerId;
  final String ownerPk;
  final List<Map<String, dynamic>> revokePackages = [];
  List<Object> revokeOutcomes = [];

  @override
  Future<ChannelDetailModel> getChannelDetail({required String channelId}) async =>
      ChannelDetailModel(
        channelId: channelId,
        name: 'Kênh',
        currentEpoch: 2,
        membershipVersion: 2,
        myRole: ChannelRole.owner,
      );

  @override
  Future<List<ChannelMemberModel>> getChannelMembers({required String channelId}) async => [
        ChannelMemberModel(deviceId: ownerId, deviceName: 'Owner', publicKey: ownerPk),
      ];

  @override
  Future<Map<String, dynamic>> revokeMembers({
    required String channelId,
    required List<String> revokeDeviceIds,
    required Map<String, dynamic> package,
  }) async {
    _events.add('server.revoke');
    revokePackages.add(package);
    final outcome = revokeOutcomes.isEmpty ? <String, dynamic>{'current_epoch': 3} : revokeOutcomes.removeAt(0);
    if (outcome is Exception) throw outcome;
    return outcome as Map<String, dynamic>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class _PairingApi implements PairingApiService {
  @override
  Future<Map<String, dynamic>> approvePairingRequest({
    required String requestId,
    required Map<String, dynamic> package,
  }) async {
    _events.add('server.approve');
    return {'current_epoch': 3};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class _DeviceApi implements DeviceApiService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class _DeviceStorage implements DeviceStorageService {
  @override
  Future<String?> getDeviceId() async => 'owner-1';
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

void main() {
  late _ChannelApi channelApi;
  late _KeyStore keyStore;
  late ChannelRepositoryImpl repo;

  setUp(() async {
    _events.clear();
    final crypto = ChannelCryptoHelper();
    final identity = await crypto.generateX25519IdentityKeyPair();
    keyStore = _KeyStore(identity);
    channelApi = _ChannelApi('owner-1', identity.publicKeyBase64);
    repo = ChannelRepositoryImpl(
      channelApiService: channelApi,
      pairingApiService: _PairingApi(),
      deviceApiService: _DeviceApi(),
      keyStore: keyStore,
      cryptoHelper: crypto,
      deviceStorage: _DeviceStorage(),
      relayBridge: _Bridge(),
      retryBaseDelay: Duration.zero,
    );
  });

  test('approve: key is saved and staged BEFORE the server commit, promoted after', () async {
    final epoch = await repo.approveRequest(
      channelId: 'ch-1',
      request: const PairingRequestModel(requestId: 'req-1'),
    );

    expect(epoch, 3);
    expect(_events, ['keystore.save:3', 'native.stage:3', 'server.approve', 'native.promote:3']);
    expect(keyStore.keys['ch-1#3'], isNotNull);
  });

  test('revoke: network failure → resends the byte-identical package, then promotes', () async {
    channelApi.revokeOutcomes = [
      const NetworkException('timeout'),
      <String, dynamic>{'current_epoch': 3, 'replayed': true},
    ];

    final epoch = await repo.revokeMembers(channelId: 'ch-1', revokeDeviceIds: ['m-1']);

    expect(epoch, 3);
    expect(channelApi.revokePackages, hasLength(2));
    expect(channelApi.revokePackages[1], channelApi.revokePackages[0]);
    expect(_events.last, 'native.promote:3');
    expect(_events, isNot(contains('native.discard:3')));
  });

  test('revoke: definitive 4xx → staged key is discarded', () async {
    channelApi.revokeOutcomes = [
      const ApiException('stale', statusCode: 409, errorCode: 'MEMBERSHIP_CHANGED'),
    ];

    await expectLater(
      repo.revokeMembers(channelId: 'ch-1', revokeDeviceIds: ['m-1']),
      throwsA(isA<ApiException>()),
    );
    expect(_events, ['keystore.save:3', 'native.stage:3', 'server.revoke', 'native.discard:3']);
  });

  test('revoke: outcome still unknown after retries → key stays pending (no discard)', () async {
    channelApi.revokeOutcomes = [
      const NetworkException('down'),
      const NetworkException('down'),
      const ApiException('bad gateway', statusCode: 502),
    ];

    await expectLater(
      repo.revokeMembers(channelId: 'ch-1', revokeDeviceIds: ['m-1']),
      throwsA(isA<AppException>()),
    );
    expect(channelApi.revokePackages, hasLength(3));
    expect(_events, isNot(contains('native.discard:3')));
    expect(_events, isNot(contains('native.promote:3')));
    expect(keyStore.keys['ch-1#3'], isNotNull);
  });
}
