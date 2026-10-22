import 'package:dio/dio.dart';

import '../models/channel_message_model.dart';

/// Service API Tin nhắn (BE: Messages endpoints, API spec §6).
abstract class MessageApiService {
  Future<SendMessageResultModel> sendMessage({
    required String channelId,
    required int keyEpoch,
    required String ciphertextBase64,
    required String nonceBase64,
  });

  Future<({List<ChannelMessageModel> messages, bool truncated})> fetchMessagesByDate({
    required String date,
    int tzOffset = 0,
    CancelToken? cancelToken,
  });

  /// `GET /channels/message` (§6.4) — đúng một tin, dùng khi nhận FCM
  /// `NEW_MESSAGE` để giải mã và hiện OTP trên thông báo.
  Future<ChannelMessageModel> fetchMessage({
    required String channelId,
    required int sequenceNumber,
    CancelToken? cancelToken,
  });
}
