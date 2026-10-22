import '../models/channel_activity_entry.dart';
import '../models/channel_event.dart';

/// Nhật ký sự kiện kênh trên máy (tab Hoạt động). Ghi được từ cả isolate
/// chính lẫn isolate FCM nền.
abstract class ChannelActivityLogStore {
  /// Số sự kiện giữ lại (mới nhất trước).
  static const int capacity = 50;

  /// Ghi [event] nếu là loại đáng hiển thị; bỏ qua tin nhắn mới (đã có tab SMS)
  /// và thao tác mở thông báo (sự kiện gốc đã được ghi khi chuông tới).
  Future<void> record(ChannelEvent event, {DateTime? at});

  /// Đọc lại từ đĩa để thấy cả sự kiện isolate nền vừa ghi.
  Future<List<ChannelActivityEntry>> load();
}
