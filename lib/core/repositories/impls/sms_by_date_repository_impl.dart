import 'package:dio/dio.dart';

import '../../models/channel_message_model.dart';
import '../../services/channel_key_store.dart';
import '../../services/message_api_service.dart';
import '../../utils/channel_crypto_helper.dart';
import '../sms_by_date_repository.dart';

class SmsByDateRepositoryImpl implements SmsByDateRepository {
  SmsByDateRepositoryImpl({
    required MessageApiService messageApiService,
    required ChannelKeyStore keyStore,
    required ChannelCryptoHelper cryptoHelper,
  }) : _messageApi = messageApiService,
       _keyStore = keyStore,
       _crypto = cryptoHelper;

  final MessageApiService _messageApi;
  final ChannelKeyStore _keyStore;
  final ChannelCryptoHelper _crypto;

  @override
  Future<({List<ChannelMessageModel> messages, bool truncated})> fetchByDate({
    required DateTime date,
    int tzOffsetMinutes = 0,
    CancelToken? cancelToken,
  }) async {
    final dateStr = _formatDate(date);
    final fetched = await _messageApi.fetchMessagesByDate(
      date: dateStr,
      tzOffset: tzOffsetMinutes,
      cancelToken: cancelToken,
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
      return message.copyWithDecryptFailed();
    }
    try {
      final decryptedText = await _crypto.decryptMessage(
        ciphertextBase64: message.ciphertext,
        nonceBase64: message.nonce,
        channelKeyBase64: key,
        channelId: message.channelId,
        keyEpoch: message.keyEpoch,
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
