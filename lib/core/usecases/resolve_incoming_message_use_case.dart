import '../crypto/channel_crypto_helper.dart';
import '../models/channel_message_model.dart';
import '../services/channel_key_store.dart';
import '../services/message_api_service.dart';
import '../utils/app_logger.dart';
import 'sync_channel_keys_use_case.dart';

/// Lấy đúng một tin vừa được báo qua FCM (`NEW_MESSAGE`) và giải mã cục bộ.
///
/// FCM chỉ là chuông (I5): payload chỉ có `channel_id` + `sequence_number`,
/// ciphertext luôn được tải qua API (§6.4) và giải mã bằng key trên máy.
///
/// - Lỗi mạng / server → ném ra để caller hiện thông báo chung.
/// - Thiếu key của `key_epoch` (vd. kênh vừa xoay khoá mà app chưa mở — server
///   không báo cho member còn lại) → lấy envelope ngay qua [SyncChannelKeysUseCase]
///   cho đúng kênh đó (1 request) rồi giải mã (FLOW_AUDIT K2). Tin tới không
///   theo thứ tự không sao: key chọn theo epoch của chính tin.
/// - Vẫn thiếu key / giải mã thất bại → `decryptFailed = true`.
///
/// Không phụ thuộc widget tree nên chạy được cả trong isolate nền của FCM.
class ResolveIncomingMessageUseCase {
  ResolveIncomingMessageUseCase({
    required MessageApiService messageApiService,
    required ChannelKeyStore keyStore,
    required ChannelCryptoHelper cryptoHelper,
    SyncChannelKeysUseCase? syncChannelKeys,
  }) : _messageApi = messageApiService,
       _keyStore = keyStore,
       _crypto = cryptoHelper,
       _syncChannelKeys = syncChannelKeys;

  final MessageApiService _messageApi;
  final ChannelKeyStore _keyStore;
  final ChannelCryptoHelper _crypto;
  final SyncChannelKeysUseCase? _syncChannelKeys;

  Future<ChannelMessageModel> call({
    required String channelId,
    required int sequenceNumber,
  }) async {
    final message = await _messageApi.fetchMessage(
      channelId: channelId,
      sequenceNumber: sequenceNumber,
    );

    var key = await _keyStore.getChannelKey(
      channelId: message.channelId,
      epoch: message.keyEpoch,
    );
    final sync = _syncChannelKeys;
    if (key == null && sync != null) {
      try {
        await sync(channelId: message.channelId);
        key = await _keyStore.getChannelKey(channelId: message.channelId, epoch: message.keyEpoch);
      } catch (error) {
        AppLogger.w('ResolveIncomingMessage', 'Key sync for ${message.channelId}@${message.keyEpoch} failed', error);
      }
    }
    if (key == null) return message.copyWithDecryptFailed();

    try {
      final plaintext = await _crypto.decryptMessage(
        ciphertextBase64: message.ciphertext,
        nonceBase64: message.nonce,
        channelKeyBase64: key,
        channelId: message.channelId,
        keyEpoch: message.keyEpoch,
        // KHÔNG truyền sequence_number: Owner (OtpRelayWorker) mã hoá trước khi
        // server cấp sequence nên AAD luôn dùng sequenceHint = 0 — giống
        // SmsByDateRepository. Truyền sequence thật → AAD lệch → luôn giải mã
        // thất bại (lỗi của 1.2, xem docs/FLOW_AUDIT.md).
      );
      return message.copyWithDecrypted(plaintext);
    } catch (_) {
      return message.copyWithDecryptFailed();
    }
  }
}
