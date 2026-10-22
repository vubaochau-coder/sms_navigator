import '../crypto/channel_crypto_helper.dart';
import '../services/channel_api_service.dart';
import '../services/channel_key_store.dart';
import '../services/device_storage_service.dart';
import '../utils/app_logger.dart';

/// Kết quả một lượt đồng bộ key.
class ChannelKeySyncResult {
  const ChannelKeySyncResult({this.added = 0, this.failed = 0});

  /// Số (kênh, epoch) mới được lưu.
  final int added;

  /// Envelope không mở được (hỏng / sai AAD) — bỏ qua, không chặn phần còn lại.
  final int failed;

  static const ChannelKeySyncResult none = ChannelKeySyncResult();
}

/// Giữ key của **mọi** epoch được cấp cho máy này (SRD §8.4) bằng **một**
/// request `GET /key-envelopes` (§6.1b), thay cho `detail + key-envelope`
/// từng kênh và chỉ epoch mới nhất (FLOW_AUDIT K1/K2).
///
/// - Epoch đã có key thì bỏ qua (không unwrap lại).
/// - Dùng khi mở app (`StartupReconcile`), khi thông báo / màn SMS gặp tin
///   thiếu key, và lần mở đầu sau khi khôi phục bản sao lưu cũ.
/// - Lỗi mạng ném ra cho caller; lỗi từng envelope chỉ được đếm.
///
/// Không phụ thuộc widget tree → chạy được trong isolate nền của FCM.
class SyncChannelKeysUseCase {
  SyncChannelKeysUseCase({
    required ChannelApiService channelApiService,
    required ChannelKeyStore keyStore,
    required DeviceStorageService deviceStorage,
    required ChannelCryptoHelper cryptoHelper,
  }) : _api = channelApiService,
       _keyStore = keyStore,
       _deviceStorage = deviceStorage,
       _crypto = cryptoHelper;

  final ChannelApiService _api;
  final ChannelKeyStore _keyStore;
  final DeviceStorageService _deviceStorage;
  final ChannelCryptoHelper _crypto;

  Future<ChannelKeySyncResult> call({String? channelId}) async {
    final identity = await _keyStore.loadIdentityKeyPair();
    final deviceId = await _deviceStorage.getDeviceId();
    if (identity == null || deviceId == null || deviceId.isEmpty) return ChannelKeySyncResult.none;

    final channels = await _api.listKeyEnvelopes(channelId: channelId);

    var added = 0;
    var failed = 0;
    for (final channel in channels) {
      if (channel.ownerPublicKey.isEmpty || channel.envelopes.isEmpty) continue;
      final have = (await _keyStore.listProvisionedEpochs(channel.channelId)).toSet();

      for (final envelope in channel.envelopes) {
        if (have.contains(envelope.keyEpoch)) continue;
        try {
          final channelKey = await _crypto.unwrapKeyEnvelope(
            wrappedKeyBase64: envelope.wrappedKey,
            nonceBase64: envelope.nonce,
            myPrivateKeyBase64: identity.privateKeyBase64,
            ownerPublicKeyBase64: channel.ownerPublicKey,
            channelId: channel.channelId,
            keyEpoch: envelope.keyEpoch,
            myDeviceId: deviceId,
          );
          await _keyStore.saveChannelKey(
            channelId: channel.channelId,
            epoch: envelope.keyEpoch,
            channelKeyBase64: channelKey,
          );
          added++;
        } catch (error) {
          failed++;
          AppLogger.w(
            'SyncChannelKeys',
            'Cannot open envelope ${channel.channelId}@${envelope.keyEpoch}',
            error,
          );
        }
      }
    }

    if (added > 0 || failed > 0) {
      AppLogger.i('SyncChannelKeys', 'Provisioned $added key(s), $failed failed (channel: ${channelId ?? 'all'})');
    }
    return ChannelKeySyncResult(added: added, failed: failed);
  }
}
