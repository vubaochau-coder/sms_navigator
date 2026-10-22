import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/crypto/channel_crypto_helper.dart';
import 'package:sms_navigator/core/models/key_envelope_model.dart';
import 'package:sms_navigator/core/services/channel_api_service.dart';
import 'package:sms_navigator/core/services/channel_key_store.dart';
import 'package:sms_navigator/core/services/device_storage_service.dart';
import 'package:sms_navigator/core/usecases/sync_channel_keys_use_case.dart';

class _Api implements ChannelApiService {
  List<ChannelKeyEnvelopesModel> response = [];
  final List<String?> calls = [];

  @override
  Future<List<ChannelKeyEnvelopesModel>> listKeyEnvelopes({String? channelId}) async {
    calls.add(channelId);
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class _Keys implements ChannelKeyStore {
  _Keys(this.identity);
  final IdentityKeyPair identity;
  final Map<String, String> keys = {};

  @override
  Future<IdentityKeyPair?> loadIdentityKeyPair() async => identity;
  @override
  Future<String?> getChannelKey({required String channelId, required int epoch}) async => keys['$channelId#$epoch'];
  @override
  Future<void> saveChannelKey({required String channelId, required int epoch, required String channelKeyBase64}) async {
    keys['$channelId#$epoch'] = channelKeyBase64;
  }

  @override
  Future<List<int>> listProvisionedEpochs(String channelId) async => [
    for (final k in keys.keys)
      if (k.startsWith('$channelId#')) int.parse(k.split('#').last),
  ]..sort();

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class _Storage implements DeviceStorageService {
  @override
  Future<String?> getDeviceId() async => 'member-1';
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

void main() {
  final crypto = ChannelCryptoHelper();
  late IdentityKeyPair owner;
  late IdentityKeyPair member;
  late _Api api;
  late _Keys keys;
  late SyncChannelKeysUseCase sync;

  Future<KeyEnvelopeModel> envelope(String channelId, int epoch, String channelKey) async {
    final wrapped = await crypto.wrapKeyForDevice(
      channelKeyBase64: channelKey,
      ownerPrivateKeyBase64: owner.privateKeyBase64,
      receiverPublicKeyBase64: member.publicKeyBase64,
      channelId: channelId,
      keyEpoch: epoch,
      receiverDeviceId: 'member-1',
    );
    return KeyEnvelopeModel(
      keyEpoch: epoch,
      wrappedKey: wrapped.wrappedKeyBase64,
      nonce: wrapped.nonceBase64,
      kekAlg: wrapped.kekAlg,
    );
  }

  setUp(() async {
    owner = await crypto.generateX25519IdentityKeyPair();
    member = await crypto.generateX25519IdentityKeyPair();
    api = _Api();
    keys = _Keys(member);
    sync = SyncChannelKeysUseCase(
      channelApiService: api,
      keyStore: keys,
      deviceStorage: _Storage(),
      cryptoHelper: crypto,
    );
  });

  test('fills every missing epoch, not just the latest, in one request (SRD §8.4)', () async {
    final k3 = crypto.generateChannelKeyBase64();
    final k4 = crypto.generateChannelKeyBase64();
    final k5 = crypto.generateChannelKeyBase64();
    keys.keys['ch#3'] = k3; // already had epoch 3
    api.response = [
      ChannelKeyEnvelopesModel(
        channelId: 'ch',
        currentEpoch: 5,
        ownerPublicKey: owner.publicKeyBase64,
        envelopes: [await envelope('ch', 3, k3), await envelope('ch', 4, k4), await envelope('ch', 5, k5)],
      ),
    ];

    final result = await sync();

    expect(api.calls, [null]);
    expect(result.added, 2);
    expect(result.failed, 0);
    expect(keys.keys, {'ch#3': k3, 'ch#4': k4, 'ch#5': k5});
  });

  test('a broken envelope is counted and skipped, the rest still lands', () async {
    final k1 = crypto.generateChannelKeyBase64();
    final good = await envelope('ch', 1, k1);
    final bad = await envelope('other-channel', 2, crypto.generateChannelKeyBase64()); // AAD bound to another channel
    api.response = [
      ChannelKeyEnvelopesModel(
        channelId: 'ch',
        currentEpoch: 2,
        ownerPublicKey: owner.publicKeyBase64,
        envelopes: [good, KeyEnvelopeModel(keyEpoch: 2, wrappedKey: bad.wrappedKey, nonce: bad.nonce)],
      ),
    ];

    final result = await sync(channelId: 'ch');

    expect(api.calls, ['ch']);
    expect(result.added, 1);
    expect(result.failed, 1);
    expect(keys.keys, {'ch#1': k1});
  });

  test('nothing to do when everything is already provisioned', () async {
    final k1 = crypto.generateChannelKeyBase64();
    keys.keys['ch#1'] = k1;
    api.response = [
      ChannelKeyEnvelopesModel(
        channelId: 'ch',
        currentEpoch: 1,
        ownerPublicKey: owner.publicKeyBase64,
        envelopes: [await envelope('ch', 1, k1)],
      ),
    ];

    expect((await sync()).added, 0);
  });
}
