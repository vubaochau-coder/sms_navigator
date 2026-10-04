import 'dart:convert';

import '../../storage/storage_keys.dart';
import '../../utils/channel_crypto_helper.dart';
import '../channel_key_store.dart';
import '../impls/secure_storage_service_impl.dart';
import '../secure_storage_service.dart';

class ChannelKeyStoreImpl implements ChannelKeyStore {
  ChannelKeyStoreImpl({
    SecureStorageService? secureStorage,
    ChannelCryptoHelper? cryptoHelper,
  }) : _secure = secureStorage ?? SecureStorageServiceImpl(),
       _crypto = cryptoHelper ?? ChannelCryptoHelper();

  final SecureStorageService _secure;
  final ChannelCryptoHelper _crypto;

  String _epochRegistryKey(String channelId) =>
      '${StorageKeys.channelKeyEpochsPrefix}$channelId';

  String _channelKeyKey(String channelId, int epoch) =>
      '${StorageKeys.channelKeyPrefix}${channelId}__$epoch';

  @override
  Future<IdentityKeyPair> getOrCreateIdentityKeyPair() async {
    final existing = await loadIdentityKeyPair();
    if (existing != null) return existing;

    final keyPair = await _crypto.generateX25519IdentityKeyPair();
    await _secure.write(
      StorageKeys.channelIdentityPrivateKey,
      keyPair.privateKeyBase64,
    );
    await _secure.write(
      StorageKeys.channelIdentityPublicKey,
      keyPair.publicKeyBase64,
    );
    return keyPair;
  }

  @override
  Future<IdentityKeyPair?> loadIdentityKeyPair() async {
    final privateSeed = await _secure.read(StorageKeys.channelIdentityPrivateKey);
    if (privateSeed == null || privateSeed.isEmpty) return null;
    final publicKey = await _secure.read(StorageKeys.channelIdentityPublicKey);
    return IdentityKeyPair(
      privateKeyBase64: privateSeed,
      publicKeyBase64: publicKey ?? '',
    );
  }

  @override
  Future<String?> getChannelKey({
    required String channelId,
    required int epoch,
  }) async {
    return _secure.read(_channelKeyKey(channelId, epoch));
  }

  @override
  Future<void> saveChannelKey({
    required String channelId,
    required int epoch,
    required String channelKeyBase64,
  }) async {
    await _secure.write(_channelKeyKey(channelId, epoch), channelKeyBase64);
    final epochs = await listProvisionedEpochs(channelId);
    if (!epochs.contains(epoch)) {
      final updated = List<int>.from(epochs)..add(epoch)..sort();
      await _secure.write(
        _epochRegistryKey(channelId),
        jsonEncode(updated),
      );
    }
  }

  @override
  Future<List<int>> listProvisionedEpochs(String channelId) async {
    final raw = await _secure.read(_epochRegistryKey(channelId));
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.map((e) => (e as num).toInt()).toList()..sort();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> purgeChannelKeys(String channelId) async {
    final epochs = await listProvisionedEpochs(channelId);
    for (final epoch in epochs) {
      await _secure.delete(_channelKeyKey(channelId, epoch));
    }
    await _secure.delete(_epochRegistryKey(channelId));
  }
}
