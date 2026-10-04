import 'dart:convert';

import 'package:sms_navigator/core/storage/secure_storage_service.dart';
import 'package:sms_navigator/core/storage/storage_keys.dart';
import 'package:sms_navigator/core/utils/channel_crypto_helper.dart';

/// Kho lưu trữ an toàn cho key material của kiến trúc Channel E2EE:
/// - Identity key X25519 của thiết bị (SRD 3.1, reinstall = identity mới).
/// - Map `epoch → Channel Key` cho từng kênh (SRD 8.4 — giữ mọi epoch còn
///   nằm trong retention để decrypt được tin nhắn ngày cũ).
abstract class ChannelKeyStore {
  /// Đọc identity key; nếu chưa có thì sinh mới và lưu vào secure storage.
  Future<IdentityKeyPair> getOrCreateIdentityKeyPair();

  /// Đọc identity key (không sinh mới); null nếu thiết bị chưa đăng ký.
  Future<IdentityKeyPair?> loadIdentityKeyPair();

  /// Đọc Channel Key của 1 kênh ở 1 epoch; null nếu chưa được provision.
  Future<String?> getChannelKey({required String channelId, required int epoch});

  /// Lưu Channel Key cho (channelId, epoch).
  Future<void> saveChannelKey({
    required String channelId,
    required int epoch,
    required String channelKeyBase64,
  });

  /// Danh sách epoch đã provision của 1 kênh (tăng dần).
  Future<List<int>> listProvisionedEpochs(String channelId);

  /// Purge toàn bộ key material của 1 kênh (policy khi bị revoke — SRD 8.4).
  Future<void> purgeChannelKeys(String channelId);
}

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
