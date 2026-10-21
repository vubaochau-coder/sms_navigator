import '../models/channel_event.dart';

export '../notifications/fcm_background_handler.dart' show firebaseMessagingBackgroundHandler;

/// FCM "chuông" (API spec §7) + thông báo cục bộ.
abstract class FcmNotificationService {
  Future<void> initialize();
  Future<void> syncToken();

  /// Sự kiện kênh (broadcast): chuông FCM khi app đang mở, và thao tác chạm /
  /// "Sao chép" trên thông báo. Màn hình dùng để tự làm mới (MOBILE_FEATURES 1.3).
  Stream<ChannelEvent> get channelEvents;

  void dispose();
}
