import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../crypto/channel_crypto_helper.dart';
import '../models/channel_event.dart';
import '../network/api_client.dart';
import '../services/crashlytics_service.dart';
import '../services/impls/channel_activity_log_store_impl.dart';
import '../services/impls/channel_key_store_impl.dart';
import '../services/impls/device_storage_service_impl.dart';
import '../services/impls/message_api_service_impl.dart';
import '../services/local_storage_service.dart';
import '../usecases/resolve_incoming_message_use_case.dart';
import 'local_notification_presenter.dart';
import 'new_message_notifier.dart';
import 'notification_content.dart';

/// FCM khi app ở background / bị tắt (chạy trong isolate riêng, không có
/// widget tree nên tự dựng các dependency cần thiết).
///
/// - Có notification block → OS đã tự hiện banner, không làm gì thêm.
/// - Data-only `NEW_MESSAGE` (Android, API spec §7) → hiện **ngay** thông báo
///   chung, rồi tải tin (§6.4), giải mã bằng key trên máy và thay bằng OTP +
///   nút "Sao chép" (cùng id). Lỗi / quá hạn → thông báo chung giữ nguyên.
/// - Data-only kind khác → thông báo chung.
/// - Mọi sự kiện kênh (trừ tin mới) được ghi cho tab Hoạt động.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Tab Hoạt động: ghi sự kiện kênh kể cả khi OS tự hiện banner
  await _recordActivity(ChannelEvent.fromData(message.data));
  try {
    if (message.notification != null) return;

    final presenter = LocalNotificationPresenter();
    await presenter.initialize();

    final event = ChannelEvent.fromData(message.data);
    final fallback = BellNotificationContent.fromRemoteMessage(message);
    if (event.kind != ChannelEventKind.newMessage) {
      await presenter.showBell(fallback);
      return;
    }

    final notifier = await _buildNotifier(presenter);
    await notifier.handle(event, fallback: fallback, placeholderFirst: true);
  } catch (error, stack) {
    // Firebase chỉ cần cho Crashlytics → khởi tạo lúc có lỗi, không làm chậm
    // đường hiện thông báo.
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
    } catch (_) {}
    await CrashlyticsService.instance.recordError(
      error,
      stack,
      reason: 'FCM background handler failed for message ${message.messageId}',
    );
  }
}

Future<void> _recordActivity(ChannelEvent event) async {
  try {
    final localStorage = await LocalStorageService.create();
    await ChannelActivityLogStoreImpl(localStorage).record(event);
  } catch (_) {
    // Chỉ phục vụ hiển thị — không được chặn thông báo.
  }
}

const Duration _backgroundRequestTimeout = Duration(seconds: 10);

Future<NewMessageNotifier> _buildNotifier(LocalNotificationPresenter presenter) async {
  final localStorage = await LocalStorageService.create();
  final deviceStorage = DeviceStorageServiceImpl(localStorage);
  final crypto = ChannelCryptoHelper();
  final apiClient = ApiClient(
    serverUrlProvider: deviceStorage.getServerUrl,
    tokenProvider: deviceStorage.getDeviceToken,
    // Android chỉ cho tác vụ FCM nền chạy ngắn; quá hạn thì thông báo chung
    // (đã hiện sẵn) vẫn ở đó.
    requestTimeout: _backgroundRequestTimeout,
  );
  return NewMessageNotifier(
    resolveIncomingMessage: ResolveIncomingMessageUseCase(
      messageApiService: MessageApiServiceImpl(apiClient: apiClient),
      keyStore: ChannelKeyStoreImpl(cryptoHelper: crypto),
      cryptoHelper: crypto,
    ),
    deviceStorage: deviceStorage,
    presenter: presenter,
    preferences: localStorage,
  );
}
