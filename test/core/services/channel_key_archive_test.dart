import 'package:flutter_test/flutter_test.dart';
import 'package:sms_navigator/core/crypto/channel_crypto_helper.dart';
import 'package:sms_navigator/core/services/impls/channel_key_store_impl.dart';
import 'package:sms_navigator/core/services/secure_storage_service.dart';

class _MemorySecureStorage implements SecureStorageService {
  final Map<String, String> data = {};

  @override
  Future<String?> read(String key) async => data[key];
  @override
  Future<void> write(String key, String value) async {
    data[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    data.remove(key);
  }

  @override
  Future<bool> containsKey(String key) async => data.containsKey(key);
  @override
  Future<Map<String, String>> readAll() async => Map.of(data);
}

void main() {
  late _MemorySecureStorage secure;
  late ChannelKeyStoreImpl store;

  setUp(() {
    secure = _MemorySecureStorage()..data['device_token'] = 'not-a-channel-key';
    store = ChannelKeyStoreImpl(secureStorage: secure, cryptoHelper: ChannelCryptoHelper());
  });

  test('exportChannelKeys returns every channel and epoch, nothing else', () async {
    await store.saveChannelKey(channelId: 'ch-a', epoch: 1, channelKeyBase64: 'a1');
    await store.saveChannelKey(channelId: 'ch-a', epoch: 2, channelKeyBase64: 'a2');
    await store.saveChannelKey(channelId: 'ch-b', epoch: 7, channelKeyBase64: 'b7');

    expect(await store.exportChannelKeys(), {
      'ch-a': {1: 'a1', 2: 'a2'},
      'ch-b': {7: 'b7'},
    });
  });

  test('importChannelKeys + restoreIdentityKeyPair make keys readable through the normal API', () async {
    await store.importChannelKeys(const {
      'ch-a': {3: 'a3'},
    });
    await store.restoreIdentityKeyPair(
      const IdentityKeyPair(privateKeyBase64: 'priv', publicKeyBase64: 'pub'),
    );

    expect(await store.getChannelKey(channelId: 'ch-a', epoch: 3), 'a3');
    expect(await store.listProvisionedEpochs('ch-a'), [3]);
    expect(
      await store.loadIdentityKeyPair(),
      const IdentityKeyPair(privateKeyBase64: 'priv', publicKeyBase64: 'pub'),
    );
  });

  test('a purged channel is not exported', () async {
    await store.saveChannelKey(channelId: 'ch-a', epoch: 1, channelKeyBase64: 'a1');
    await store.purgeChannelKeys('ch-a');
    expect(await store.exportChannelKeys(), isEmpty);
  });
}
