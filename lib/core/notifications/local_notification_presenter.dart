import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../l10n/app_l10n.dart';
import 'notification_content.dart';

/// Lớp mỏng bọc `flutter_local_notifications`: một kênh Android, thông báo
/// chung và thông báo OTP có nút "Sao chép". Dùng chung cho isolate chính
/// và isolate nền của FCM (mỗi isolate tự gọi [initialize]).
class LocalNotificationPresenter {
  LocalNotificationPresenter([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String androidChannelId = 'sms_navigator_otp_channel';
  static const String androidChannelName = 'SMS Navigator';
  static const String copyActionId = 'copy_otp';

  final FlutterLocalNotificationsPlugin _plugin;

  Future<void> initialize({DidReceiveNotificationResponseCallback? onResponse}) async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: onResponse,
    );

    final android = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      AndroidNotificationChannel(
        androidChannelId,
        androidChannelName,
        description: AppL10n.current.notificationChannelDescription,
        importance: Importance.high,
      ),
    );
  }

  /// Phản hồi đã mở app từ trạng thái bị tắt (cold start), nếu có.
  Future<NotificationResponse?> launchResponse() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse;
  }

  Future<void> showBell(
    BellNotificationContent content, {
    int? id,
    NotificationPayload? payload,
  }) {
    return _plugin.show(
      id: id ?? DateTime.now().millisecondsSinceEpoch % 0x7fffffff,
      title: content.title,
      body: content.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannelId,
          androidChannelName,
          channelDescription: AppL10n.current.notificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: payload?.encode(),
    );
  }

  Future<void> showOtp(OtpNotificationContent content) {
    final l10n = AppL10n.current;
    return _plugin.show(
      id: content.id,
      title: content.title,
      body: content.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          androidChannelId,
          androidChannelName,
          channelDescription: l10n.notificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
          category: AndroidNotificationCategory.message,
          // Màn hình khoá an toàn chỉ hiện "có nội dung bị ẩn", không lộ OTP.
          visibility: NotificationVisibility.private,
          subText: content.channelName,
          styleInformation: BigTextStyleInformation(
            content.body,
            contentTitle: content.title,
          ),
          actions: <AndroidNotificationAction>[
            AndroidNotificationAction(
              copyActionId,
              l10n.notificationCopyAction,
              // Sao chép cần app ở foreground (clipboard + toast).
              showsUserInterface: true,
              cancelNotification: true,
            ),
          ],
        ),
      ),
      payload: content.payload.encode(),
    );
  }
}
