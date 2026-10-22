import 'package:dio/dio.dart';

import '../../models/channel_event.dart';
import '../../errors/app_exceptions.dart';
import '../../models/channel_message_model.dart';
import '../../services/channel_key_store.dart';
import '../../services/message_api_service.dart';
import '../../services/message_cache_store.dart';
import '../../crypto/channel_crypto_helper.dart';
import '../sms_by_date_repository.dart';

class SmsByDateRepositoryImpl implements SmsByDateRepository {
  SmsByDateRepositoryImpl({
    required MessageApiService messageApiService,
    required ChannelKeyStore keyStore,
    required ChannelCryptoHelper cryptoHelper,
    Stream<ChannelEvent> channelEvents = const Stream.empty(),
    MessageCacheStore? cache,
  }) : _cache = cache,
       _messageApi = messageApiService,
       _keyStore = keyStore,
       _crypto = cryptoHelper,
       _channelEvents = channelEvents;

  final MessageCacheStore? _cache;
  final MessageApiService _messageApi;
  final ChannelKeyStore _keyStore;
  final ChannelCryptoHelper _crypto;
  final Stream<ChannelEvent> _channelEvents;

  @override
  Stream<ChannelEvent> get messageChanges =>
      _channelEvents.where((event) => event.affectsMessages);

  @override
  Future<({List<ChannelMessageModel> messages, bool truncated, DateTime? cachedAt})> fetchByDate({
    required DateTime date,
    int tzOffsetMinutes = 0,
    CancelToken? cancelToken,
  }) async {
    final dateStr = _formatDate(date);
    final dayKey = '$dateStr@$tzOffsetMinutes';
    final ({List<ChannelMessageModel> messages, bool truncated}) fetched;
    try {
      fetched = await _messageApi.fetchMessagesByDate(
        date: dateStr,
        tzOffset: tzOffsetMinutes,
        cancelToken: cancelToken,
      );
    } on NetworkException {
      // BACKLOG 1.7: không có mạng → bản lưu (nếu có), giải mã lại tại chỗ.
      final cached = _cache?.load(dayKey);
      if (cached == null) rethrow;
      final decrypted = await _decryptAll(cached.messages);
      return (
        // Kênh đã rời / bị thu hồi: key đã purge → bỏ khỏi bản lưu
        messages: decrypted.where((m) => !m.decryptFailed).toList(),
        truncated: cached.truncated,
        cachedAt: cached.savedAt,
      );
    }

    await _cache?.save(dayKey, fetched.messages, truncated: fetched.truncated);
    return (
      messages: await _decryptAll(fetched.messages),
      truncated: fetched.truncated,
      cachedAt: null,
    );
  }

  /// Giải mã cả ngày trong một lượt:
  /// - mỗi cặp (kênh, epoch) chỉ đọc key từ secure storage **một lần**
  ///   (mỗi lần đọc là một lời gọi platform channel);
  /// - giải mã theo lô qua [ChannelCryptoHelper.decryptMessages] (lô lớn chạy
  ///   ngoài main isolate).
  Future<List<ChannelMessageModel>> _decryptAll(List<ChannelMessageModel> messages) async {
    final keyCache = <String, String?>{};
    final jobs = <MessageDecryptJob>[];
    final jobIndexOf = List<int?>.filled(messages.length, null);

    for (var i = 0; i < messages.length; i++) {
      final message = messages[i];
      final cacheKey = '${message.channelId}#${message.keyEpoch}';
      String? key;
      if (keyCache.containsKey(cacheKey)) {
        key = keyCache[cacheKey];
      } else {
        key = await _keyStore.getChannelKey(channelId: message.channelId, epoch: message.keyEpoch);
        keyCache[cacheKey] = key;
      }
      if (key == null) continue;
      jobIndexOf[i] = jobs.length;
      jobs.add(MessageDecryptJob(
        ciphertextBase64: message.ciphertext,
        nonceBase64: message.nonce,
        channelKeyBase64: key,
        channelId: message.channelId,
        keyEpoch: message.keyEpoch,
      ));
    }

    final plaintexts = await _crypto.decryptMessages(jobs);

    return [
      for (var i = 0; i < messages.length; i++)
        switch (jobIndexOf[i]) {
          final int j when plaintexts[j] != null => messages[i].copyWithDecrypted(plaintexts[j]!),
          _ => messages[i].copyWithDecryptFailed(),
        },
    ];
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }
}
