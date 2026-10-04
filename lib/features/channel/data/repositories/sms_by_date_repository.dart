import '../../../../core/utils/channel_crypto_helper.dart';
import '../models/channel_message_model.dart';
import '../services/channel_api_client.dart';
import '../services/channel_key_store.dart';

/// Kết quả decrypt 1 dòng tin nhắn SMS / OTP.
enum SmsDecryptStatus { ok, missingKey, failed }

/// Repository đọc SMS theo ngày (MOBILE_FEATURES 6.1–6.4):
/// `GET /messages?date&tz_offset` — gộp SMS của TẤT CẢ kênh caller đang
/// ACTIVE, điều kiện duy nhất là ngày (không chọn kênh). Mỗi lần mở là một
/// lần fetch — không có local message store (SRD 8.4).
class SmsByDateRepository {
  SmsByDateRepository({
    required ChannelApiClient apiClient,
    required ChannelKeyStore keyStore,
    required ChannelCryptoHelper cryptoHelper,
  }) : _api = apiClient,
       _keyStore = keyStore,
       _crypto = cryptoHelper;

  final ChannelApiClient _api;
  final ChannelKeyStore _keyStore;
  final ChannelCryptoHelper _crypto;

  /// Fetch + decrypt từng tin theo ngày (tz_offset = phút so với UTC).
  /// Kênh đã bị revoke tự bị server loại khỏi kết quả (KL12) — client purge
  /// key material theo policy nên message thiếu key sẽ hiển thị trạng thái lỗi.
  Future<({List<ChannelMessageModel> messages, bool truncated})> fetchByDate({
    required DateTime date,
    int tzOffsetMinutes = 0,
  }) async {
    final dateStr = _formatDate(date);
    final fetched = await _api.fetchMessagesByDate(
      date: dateStr,
      tzOffset: tzOffsetMinutes,
    );

    final decrypted = <ChannelMessageModel>[];
    for (final message in fetched.messages) {
      decrypted.add(await _decryptMessage(message));
    }
    return (messages: decrypted, truncated: fetched.truncated);
  }

  Future<ChannelMessageModel> _decryptMessage(ChannelMessageModel message) async {
    final key = await _keyStore.getChannelKey(
      channelId: message.channelId,
      epoch: message.keyEpoch,
    );
    if (key == null) {
      // Chưa được provision key epoch này (fetch muộn) — không mất tin, user
      // có thể retry sau khi reconcile chạy (SRD 8.4 retention policy).
      return message.copyWithDecryptFailed();
    }
    try {
      final decryptedText = await _crypto.decryptMessage(
        ciphertextBase64: message.ciphertext,
        nonceBase64: message.nonce,
        channelKeyBase64: key,
        channelId: message.channelId,
        keyEpoch: message.keyEpoch,
        // AAD mã hóa luôn dùng seq_hint = 0 vì server mới cấp sequence sau
        // khi nhận ciphertext (API spec §11).
        sequenceHint: 0,
      );
      return message.copyWithDecrypted(decryptedText);
    } on ChannelCryptoException {
      return message.copyWithDecryptFailed();
    }
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}

/// Backward compatibility typedef
typedef OtpByDateRepository = SmsByDateRepository;
