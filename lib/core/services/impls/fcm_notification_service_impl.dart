import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../crashlytics_service.dart';
import '../device_api_service.dart';
import '../device_storage_service.dart';
import '../fcm_notification_service.dart';
import '../../utils/app_logger.dart';
import '../../l10n/app_l10n.dart';

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

class BellNotificationContent {
  const BellNotificationContent({required this.title, required this.body});

  final String title;
  final String body;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BellNotificationContent &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          body == other.body;

  @override
  int get hashCode => Object.hash(title, body);
}

class FcmNotificationServiceImpl implements FcmNotificationService {
  FcmNotificationServiceImpl({
    required DeviceStorageService deviceStorageService,
    required DeviceApiService deviceApiService,
  }) : _deviceStorage = deviceStorageService,
       _deviceApi = deviceApiService;

  final DeviceStorageService _deviceStorage;
  final DeviceApiService _deviceApi;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  StreamSubscription<String>? _tokenRefreshSubscription;
  void Function()? _channelEventListener;

  bool _initialized = false;

  @override
  void setChannelEventListener(void Function() listener) {
    _channelEventListener = listener;
  }

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidSettings);
      await _localNotifications.initialize(settings: initSettings);

      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final androidChannel = AndroidNotificationChannel(
          'sms_navigator_otp_channel',
          'SMS Navigator',
          description: AppL10n.current.notificationChannelDescription,
          importance: Importance.high,
        );
        await androidPlugin.createNotificationChannel(androidChannel);
      }

      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      FirebaseMessaging.instance.onTokenRefresh.listen(_onTokenRefreshed);

      FirebaseMessaging.onMessage.listen(_showBellNotification);

      unawaited(FirebaseMessaging.instance.requestPermission());
    } catch (error, stack) {
      AppLogger.w('FcmNotificationService', 'Initialize failed', error, stack);
    }
  }

  @override
  Future<void> syncToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await _deviceStorage.saveFcmToken(token);

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
      AppLogger.w(
        'FcmNotificationService',
        'updateFcmToken on refresh failed',
        error,
        stack,
      );
    }
  }

  @visibleForTesting
  static BellNotificationContent resolveContent(RemoteMessage message) {
    // Ưu tiên tiêu đề/nội dung từ notification block của FCM nếu server đã định dạng
    String title = message.notification?.title ?? 'SMS Navigator';
    final l10n = AppL10n.current;
    String body = message.notification?.body ?? l10n.notificationDefaultBody;

    final kind = message.data['kind'];
    final channelName = message.data['channel_name'];
    final requesterName = message.data['requester_device_name'];

    // Nếu không có notification block thì tự dựng nội dung từ data payload
    if (message.notification == null) {
      switch (kind) {
        case 'JOIN_REQUEST':
          title = l10n.notificationJoinRequestTitle;
          if (requesterName != null && requesterName.isNotEmpty && channelName != null && channelName.isNotEmpty) {
            body = l10n.notificationJoinRequestBody(requesterName, channelName);
          } else if (requesterName != null && requesterName.isNotEmpty) {
            body = l10n.notificationJoinRequestBodyNoChannel(requesterName);
          } else {
            body = l10n.notificationJoinRequestBodyGeneric;
          }
          break;
        case 'APPROVED':
          title = l10n.notificationApprovedTitle;
          if (channelName != null && channelName.isNotEmpty) {
            body = l10n.notificationApprovedBody(channelName);
          } else {
            body = l10n.notificationApprovedBodyGeneric;
          }
          break;
        case 'REVOKED':
          title = l10n.notificationRevokedTitle;
          if (channelName != null && channelName.isNotEmpty) {
            body = l10n.notificationRevokedBody(channelName);
          } else {
            body = l10n.notificationRevokedBodyGeneric;
          }
          break;
        case 'NEW_MESSAGE':
          title = l10n.notificationNewMessageTitle;
          if (channelName != null && channelName.isNotEmpty) {
            body = l10n.notificationNewMessageBody(channelName);
          } else {
            body = l10n.notificationNewMessageBodyGeneric;
          }
          break;
      }
    }

    return BellNotificationContent(title: title, body: body);
  }

  Future<void> _showBellNotification(RemoteMessage message) async {
    final androidDetails = AndroidNotificationDetails(
      'sms_navigator_otp_channel',
      'SMS Navigator',
      channelDescription: AppL10n.current.notificationChannelDescription,
      importance: Importance.high,
      priority: Priority.high,
    );
    final details = NotificationDetails(android: androidDetails);

    final content = resolveContent(message);

    try {
      await _localNotifications.show(
        id: DateTime.now().millisecondsSinceEpoch % 0x7fffffff,
        title: content.title,
        body: content.body,
        notificationDetails: details,
      );
    } catch (error, stack) {
      AppLogger.w(
        'FcmNotificationService',
        'Show bell notification failed',
        error,
        stack,
      );
    }

    try {
      _channelEventListener?.call();
    } catch (_) {}
  }

  @override
  void dispose() {
    _tokenRefreshSubscription?.cancel();
  }
}
