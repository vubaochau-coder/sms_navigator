import 'package:dio/dio.dart';

import '../models/channel_message_model.dart';

abstract class SmsByDateRepository {
  /// Fetch + decrypt từng tin theo ngày (tz_offset = phút so với UTC).
  Future<({List<ChannelMessageModel> messages, bool truncated})> fetchByDate({
    required DateTime date,
    int tzOffsetMinutes = 0,
    CancelToken? cancelToken,
  });
}

/// Backward compatibility typedef
typedef OtpByDateRepository = SmsByDateRepository;
