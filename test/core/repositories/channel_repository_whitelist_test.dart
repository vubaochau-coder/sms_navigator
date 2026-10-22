import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/crypto/channel_crypto_helper.dart';
import 'package:sms_navigator/core/models/channel_detail_model.dart';
import 'package:sms_navigator/core/models/channel_model.dart';
import 'package:sms_navigator/core/models/whitelist_config_model.dart';
import 'package:sms_navigator/core/repositories/impls/channel_repository_impl.dart';
import 'package:sms_navigator/core/repositories/impls/whitelist_repository_impl.dart';
import 'package:sms_navigator/core/services/channel_api_service.dart';
import 'package:sms_navigator/core/services/channel_key_store.dart';
import 'package:sms_navigator/core/services/device_api_service.dart';
import 'package:sms_navigator/core/services/device_storage_service.dart';
import 'package:sms_navigator/core/services/native_relay_service.dart';
import 'package:sms_navigator/core/services/pairing_api_service.dart';
import 'package:sms_navigator/core/services/relay_channel_bridge.dart';

class _KeyStore implements ChannelKeyStore {
  final Map<String, String> keys = {};

  @override
  Future<String?> getChannelKey({required String channelId, required int epoch}) async =>
      keys['$channelId#$epoch'];

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class _ChannelApi implements ChannelApiService {
  List<ChannelModel> channels = [];

  @override
  Future<List<ChannelModel>> listChannels() async => channels;

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class _NativeRelay implements NativeRelayService {
  WhitelistConfigModel cached = const WhitelistConfigModel();
  int writes = 0;

  @override
  Future<WhitelistConfigModel> getWhitelist(String channelId) async => cached;

  @override
  Future<bool> setWhitelist(String channelId, WhitelistConfigModel config) async {
    writes++;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class _Unused implements PairingApiService, DeviceApiService, DeviceStorageService, RelayChannelBridge {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

void main() {
  final crypto = ChannelCryptoHelper();
  const config = WhitelistConfigModel(
    entries: [
      WhitelistEntryModel(address: 'Vietcombank', allowOtp: true),
      WhitelistEntryModel(address: '0909123456'),
    ],
  );

  late _KeyStore keyStore;
  late _ChannelApi channelApi;
  late _NativeRelay nativeRelay;
  late ChannelRepositoryImpl repo;

  Future<ChannelWhitelistBlobModel> encryptBlob(String channelId, String key, {int epoch = 1}) async {
    final encrypted = await crypto.encryptMessage(
      plaintext: jsonEncode(config.toJson()),
      channelKeyBase64: key,
      channelId: channelId,
      keyEpoch: epoch,
      sequenceHint: 0,
    );
    return ChannelWhitelistBlobModel(
      keyEpoch: epoch,
      ciphertext: encrypted.ciphertextBase64,
      nonce: encrypted.nonceBase64,
      whitelistVersion: 4,
      updatedAt: '2026-10-22T00:00:00Z',
    );
  }

  setUp(() {
    keyStore = _KeyStore();
    channelApi = _ChannelApi();
    nativeRelay = _NativeRelay();
    final unused = _Unused();
    repo = ChannelRepositoryImpl(
      channelApiService: channelApi,
      pairingApiService: unused,
      deviceApiService: unused,
      keyStore: keyStore,
      cryptoHelper: crypto,
      deviceStorage: unused,
      relayBridge: unused,
      whitelistRepository: WhitelistRepositoryImpl(
        nativeRelayService: nativeRelay,
        channelApiService: channelApi,
        cryptoHelper: crypto,
      ),
    );
  });

  test('member decrypts the list blob with its channel key — without touching native cache', () async {
    final key = crypto.generateChannelKeyBase64();
    keyStore.keys['ch-1#1'] = key;
    channelApi.channels = [
      ChannelModel(channelId: 'ch-1', name: 'Nhà', role: ChannelRole.member, whitelistBlob: await encryptBlob('ch-1', key)),
    ];

    final channels = await repo.listChannelsWithWhitelist();

    expect(channels.single.whitelist?.entries, config.entries);
    expect(channels.single.whitelist?.version, 4);
    expect(nativeRelay.writes, 0);
  });

  test('missing key → member gets no whitelist, list still loads', () async {
    final blob = await encryptBlob('ch-1', crypto.generateChannelKeyBase64());
    channelApi.channels = [
      ChannelModel(channelId: 'ch-1', name: 'Nhà', role: ChannelRole.member, whitelistBlob: blob),
    ];

    final channels = await repo.listChannelsWithWhitelist();

    expect(channels.single.whitelist, isNull);
  });

  test('owner falls back to the native cache when the server sends no blob (old server)', () async {
    nativeRelay.cached = config;
    channelApi.channels = [const ChannelModel(channelId: 'ch-1', name: 'Nhà', role: ChannelRole.owner)];

    final channels = await repo.listChannelsWithWhitelist();

    expect(channels.single.whitelist?.entries, config.entries);
  });

  test('GET /channels whitelist field is parsed into the model', () {
    final model = ChannelModel.fromMap({
      'channel_id': 'ch-1',
      'name': 'Nhà',
      'role': 'MEMBER',
      'whitelist': {
        'key_epoch': 2,
        'ciphertext': 'c',
        'nonce': 'n',
        'whitelist_version': 3,
        'updated_at': 't',
      },
    });
    expect(model.whitelistBlob?.keyEpoch, 2);
    expect(ChannelModel.fromMap({'channel_id': 'x', 'whitelist': null}).whitelistBlob, isNull);
  });
}
