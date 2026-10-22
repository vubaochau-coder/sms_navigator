import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../l10n/app_l10n.dart';
import '../../models/channel_event.dart';
import '../../notifications/local_notification_presenter.dart';
import '../../notifications/new_message_notifier.dart';
import '../../notifications/notification_content.dart';
import '../../ui/toast_utils.dart';
import '../../usecases/resolve_incoming_message_use_case.dart';
import '../../utils/app_logger.dart';
import '../device_api_service.dart';
import '../device_storage_service.dart';
import '../fcm_notification_service.dart';
import '../local_storage_service.dart';

export '../../notifications/fcm_background_handler.dart' show firebaseMessagingBackgroundHandler;
export '../../notifications/notification_content.dart' show BellNotificationContent;

/// Sao chép chuỗi + báo cho người dùng (inject được để kiểm thử).
typedef CopyToClipboard = Future<void> Function(String text);

Future<void> _defaultCopy(String text) =>
    ToastUtils.copyToClipboard(text, successMessage: AppL10n.current.smsCopied(text));

class FcmNotificationServiceImpl implements FcmNotificationService {
  FcmNotificationServiceImpl({
    required DeviceStorageService deviceStorageService,
    required DeviceApiService deviceApiService,
    ResolveIncomingMessageUseCase? resolveIncomingMessage,
    LocalNotificationPresenter? presenter,
    CopyToClipboard? copyToClipboard,
    LocalStorageService? preferences,
  }) : _deviceStorage = deviceStorageService,
       _deviceApi = deviceApiService,
       _presenter = presenter ?? LocalNotificationPresenter(),
       _copy = copyToClipboard ?? _defaultCopy {
    final resolve = resolveIncomingMessage;
    _newMessageNotifier = resolve == null
        ? null
        : NewMessageNotifier(
            resolveIncomingMessage: resolve,
            deviceStorage: deviceStorageService,
            presenter: _presenter,
            preferences: preferences,
          );
  }

  final DeviceStorageService _deviceStorage;
  final DeviceApiService _deviceApi;
  final LocalNotificationPresenter _presenter;
  final CopyToClipboard _copy;
  late final NewMessageNotifier? _newMessageNotifier;

  final StreamController<ChannelEvent> _events = StreamController<ChannelEvent>.broadcast();
  final List<StreamSubscription<Object?>> _subscriptions = [];

  bool _initialized = false;

  @override
  Stream<ChannelEvent> get channelEvents => _events.stream;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _presenter.initialize(onResponse: handleNotificationResponse);

      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      _subscriptions
        ..add(FirebaseMessaging.instance.onTokenRefresh.listen(_onTokenRefreshed))
        ..add(FirebaseMessaging.onMessage.listen(handleForegroundMessage))
        // Chạm vào banner do OS hiện (iOS / notification block)
        ..add(FirebaseMessaging.onMessageOpenedApp.listen(_onSystemNotificationOpened));

      unawaited(FirebaseMessaging.instance.requestPermission());
      unawaited(_handleLaunchFromNotification());
    } catch (error, stack) {
      AppLogger.w('FcmNotificationService', 'Initialize failed', error, stack);
    }
  }

  /// App được mở từ trạng thái tắt hẳn bằng một thông báo.
  Future<void> _handleLaunchFromNotification() async {
    try {
      final response = await _presenter.launchResponse();
      if (response != null) await handleNotificationResponse(response);

      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _onSystemNotificationOpened(initial);
    } catch (error, stack) {
      AppLogger.w('FcmNotificationService', 'Launch details failed', error, stack);
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
  static BellNotificationContent resolveContent(RemoteMessage message) =>
      BellNotificationContent.fromRemoteMessage(message);

  /// FCM khi app đang mở: báo cho màn hình làm mới ngay, rồi hiện thông báo
  /// (OTP nếu là `NEW_MESSAGE`, ngược lại là thông báo chung).
  @visibleForTesting
  Future<void> handleForegroundMessage(RemoteMessage message) async {
    final event = ChannelEvent.fromData(message.data);
    _emit(event);

    final fallback = BellNotificationContent.fromRemoteMessage(message);
    final notifier = _newMessageNotifier;
    try {
      if (event.kind == ChannelEventKind.newMessage && notifier != null) {
        await notifier.handle(event, fallback: fallback);
      } else {
        await _presenter.showBell(fallback);
      }
    } catch (error, stack) {
      AppLogger.w('FcmNotificationService', 'Show notification failed', error, stack);
    }
  }

  /// Chạm vào thông báo cục bộ hoặc bấm "Sao chép".
  @visibleForTesting
  Future<void> handleNotificationResponse(NotificationResponse response) async {
    final payload = NotificationPayload.decode(response.payload);
    if (payload == null) return;

    if (response.actionId == LocalNotificationPresenter.copyActionId) {
      final text = payload.copyText;
      if (text != null && text.isNotEmpty) {
        try {
          await _copy(text);
        } catch (error, stack) {
          AppLogger.w('FcmNotificationService', 'Copy OTP failed', error, stack);
        }
      }
    }

    _emit(ChannelEvent(
      kind: ChannelEventKind.newMessage,
      channelId: payload.channelId,
      sequenceNumber: payload.sequenceNumber,
      openedFromNotification: true,
    ));
  }

  void _onSystemNotificationOpened(RemoteMessage message) {
    final event = ChannelEvent.fromData(message.data);
    _emit(ChannelEvent(
      kind: event.kind,
      channelId: event.channelId,
      channelName: event.channelName,
      sequenceNumber: event.sequenceNumber,
      senderDeviceId: event.senderDeviceId,
      openedFromNotification: true,
    ));
  }

  void _emit(ChannelEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    _events.close();
  }
}
