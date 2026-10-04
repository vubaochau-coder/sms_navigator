import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../features/device/data/services/device_api_service.dart';
import '../services/crashlytics_service.dart';
import '../services/device_storage_service.dart';
import '../utils/app_logger.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    debugPrint('Received background FCM message: ${message.messageId}');
  } catch (error, stack) {
    CrashlyticsService.instance.recordError(
      error,
      stack,
      reason: 'FCM background handler failed for message ${message.messageId}',
    );
  }
}

/// FCM chỉ là chuông (API spec §7, I5/N8):
/// - Data message KHÔNG chứa ciphertext/key — mất FCM vô hại vì app luôn
///   reconcile khi mở;
/// - Tap chuông → mở app → người dùng tự vào màn OTP hôm nay / màn kênh.
class FcmNotificationService {
  FcmNotificationService({
    required DeviceStorageService deviceStorageService,
    required DeviceApiService deviceApiService,
  }) : _deviceStorage = deviceStorageService,
       _deviceApi = deviceApiService;

  final DeviceStorageService _deviceStorage;
  final DeviceApiService _deviceApi;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenRefreshSubscription;

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _localNotifications.initialize(settings: initSettings);

      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.instance.onTokenRefresh.listen(_onTokenRefreshed);

      FirebaseMessaging.onMessage.listen(_showBellNotification);
    } catch (error, stack) {
      AppLogger.w('FcmNotificationService', 'Initialize failed', error, stack);
    }
  }

  /// Đăng ký / làm mới FCM token lên server (best-effort).
  Future<void> syncToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _deviceStorage.saveFcmToken(token);

      // Chỉ upload khi đã có device token (đã register).
      final deviceToken = await _deviceStorage.getDeviceToken();
      if (deviceToken == null || deviceToken.isEmpty) return;
      await _deviceApi.updateFcmToken(token);
    } catch (error, stack) {
      AppLogger.w('FcmNotificationService', 'syncToken failed', error, stack);
    }
  }

  Future<void> _onTokenRefreshed(String token) async {
    await _deviceStorage.saveFcmToken(token);
    try {
      final deviceToken = await _deviceStorage.getDeviceToken();
      if (deviceToken == null || deviceToken.isEmpty) return;
      await _deviceApi.updateFcmToken(token);
    } catch (error, stack) {
      AppLogger.w('FcmNotificationService', 'updateFcmToken on refresh failed', error, stack);
    }
  }

  /// Chuông foreground: text generic, không hiển thị dữ liệu OTP/khóa.
  Future<void> _showBellNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'channel_events',
      'Sự kiện kênh',
      channelDescription: 'Chuông báo có yêu cầu duyệt / OTP mới / thay đổi kênh',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    String title = 'SMS Navigator';
    String body = 'Có sự kiện mới trong kênh. Mở app để xem.';
    final kind = message.data['kind'];
    switch (kind) {
      case 'JOIN_REQUEST':
        title = 'Yêu cầu tham gia kênh';
        body = 'Có thiết bị mới xin tham gia. Mở app để duyệt.';
        break;
      case 'APPROVED':
        title = 'Yêu cầu đã được duyệt';
        body = 'Bạn đã được thêm vào kênh. Mở app để bắt đầu nhận OTP.';
        break;
      case 'REVOKED':
        title = 'Quyền truy cập đã bị thu hồi';
        body = 'Bạn không còn quyền truy cập một kênh.';
        break;
      case 'NEW_MESSAGE':
        title = 'OTP mới';
        body = 'Có mã OTP mới vừa được chia sẻ. Chạm để xem.';
        break;
    }

    try {
      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch % 0x7fffffff,
        title: title,
        body: body,
        notificationDetails: details,
      );
    } catch (error, stack) {
      AppLogger.w('FcmNotificationService', 'Show bell notification failed', error, stack);
    }
  }

  void dispose() {
    _tokenRefreshSubscription?.cancel();
  }
}
