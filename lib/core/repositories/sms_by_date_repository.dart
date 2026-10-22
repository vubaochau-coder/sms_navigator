import 'package:dio/dio.dart';

import '../models/channel_event.dart';
import '../models/channel_message_model.dart';

abstract class SmsByDateRepository {
  /// Fetch + decrypt từng tin theo ngày (tz_offset = phút so với UTC).
  /// Mất mạng mà có bản lưu → trả bản lưu với [cachedAt] = lúc lưu (BACKLOG 1.7);
  /// [cachedAt] null = dữ liệu mới từ server.
  Future<({List<ChannelMessageModel> messages, bool truncated, DateTime? cachedAt})> fetchByDate({
    required DateTime date,
    int tzOffsetMinutes = 0,
    CancelToken? cancelToken,
  });

  /// Sự kiện làm danh sách tin thay đổi (tin mới, được duyệt, bị thu hồi) —
  /// màn SMS lắng nghe để tự làm mới (MOBILE_FEATURES 1.3).
  Stream<ChannelEvent> get messageChanges;
}
