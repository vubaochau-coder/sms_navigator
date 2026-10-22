import '../crypto/channel_crypto_helper.dart';
import '../models/channel_message_model.dart';
import '../services/channel_key_store.dart';
import '../services/message_api_service.dart';

/// Lấy đúng một tin vừa được báo qua FCM (`NEW_MESSAGE`) và giải mã cục bộ.
///
/// FCM chỉ là chuông (I5): payload chỉ có `channel_id` + `sequence_number`,
/// ciphertext luôn được tải qua API (§6.4) và giải mã bằng key trên máy.
///
/// - Lỗi mạng / server → ném ra để caller hiện thông báo chung.
/// - Thiếu key hoặc giải mã thất bại → trả về tin với `decryptFailed = true`.
///
/// Không phụ thuộc widget tree nên chạy được cả trong isolate nền của FCM.
class ResolveIncomingMessageUseCase {
  ResolveIncomingMessageUseCase({
    required MessageApiService messageApiService,
    required ChannelKeyStore keyStore,
    required ChannelCryptoHelper cryptoHelper,
  }) : _messageApi = messageApiService,
       _keyStore = keyStore,
       _crypto = cryptoHelper;

  final MessageApiService _messageApi;
  final ChannelKeyStore _keyStore;
  final ChannelCryptoHelper _crypto;

  Future<ChannelMessageModel> call({
    required String channelId,
    required int sequenceNumber,
  }) async {
    final message = await _messageApi.fetchMessage(
      channelId: channelId,
      sequenceNumber: sequenceNumber,
    );

    final key = await _keyStore.getChannelKey(
      channelId: message.channelId,
      epoch: message.keyEpoch,
    );
    if (key == null) return message.copyWithDecryptFailed();

    try {
      final plaintext = await _crypto.decryptMessage(
        ciphertextBase64: message.ciphertext,
        nonceBase64: message.nonce,
        channelKeyBase64: key,
        channelId: message.channelId,
        keyEpoch: message.keyEpoch,
        sequenceHint: message.sequenceNumber,
      );
      return message.copyWithDecrypted(plaintext);
    } catch (_) {
      return message.copyWithDecryptFailed();
    }
  }
}
