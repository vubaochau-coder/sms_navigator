import '../constants/storage_keys.dart';
import '../models/channel_event.dart';
import '../services/device_storage_service.dart';
import '../services/local_storage_service.dart';
import '../usecases/resolve_incoming_message_use_case.dart';
import '../utils/app_logger.dart';
import 'local_notification_presenter.dart';
import 'notification_content.dart';

/// Kết quả xử lý một `NEW_MESSAGE` — chủ yếu để kiểm thử.
enum NewMessageNotifyOutcome { otpShown, fallbackShown, skippedOwnMessage }

/// Biến một chuông `NEW_MESSAGE` thành thông báo có OTP (MOBILE_FEATURES 1.2):
/// tải đúng tin đó (§6.4) → giải mã cục bộ → hiện OTP + nút "Sao chép".
///
/// Bất kỳ lỗi nào (mạng, thiếu key, giải mã hỏng) → hiện thông báo chung,
/// người dùng không bao giờ mất chuông. Tin do chính máy này gửi (Owner relay)
/// thì bỏ qua — máy đã có SMS gốc.
class NewMessageNotifier {
  NewMessageNotifier({
    required ResolveIncomingMessageUseCase resolveIncomingMessage,
    required DeviceStorageService deviceStorage,
    required LocalNotificationPresenter presenter,
    LocalStorageService? preferences,
  }) : _resolve = resolveIncomingMessage,
       _deviceStorage = deviceStorage,
       _presenter = presenter,
       _preferences = preferences;

  final ResolveIncomingMessageUseCase _resolve;
  final DeviceStorageService _deviceStorage;
  final LocalNotificationPresenter _presenter;
  final LocalStorageService? _preferences;

  /// [placeholderFirst] (isolate nền): hiện ngay thông báo chung rồi mới tải
  /// + giải mã; xong thì thay bằng OTP (cùng id). Android có thể huỷ tiến
  /// trình nền bất cứ lúc nào — người dùng luôn thấy chuông, kể cả khi bước
  /// tải tin chậm hoặc bị cắt ngang.
  Future<NewMessageNotifyOutcome> handle(
    ChannelEvent event, {
    required BellNotificationContent fallback,
    bool placeholderFirst = false,
  }) async {
    final channelId = event.channelId;
    final sequenceNumber = event.sequenceNumber;
    final stopwatch = Stopwatch()..start();

    final sender = event.senderDeviceId;
    // BACKLOG 1.8: mặc định bỏ qua tin do chính máy này relay (đã có SMS gốc).
    final notifyOwn = _preferences?.getBool(StorageKeys.notifyOwnRelayedMessages) ?? false;
    if (sender != null && !notifyOwn) {
      final myDeviceId = await _deviceStorage.getDeviceId();
      if (myDeviceId != null && myDeviceId == sender) {
        return NewMessageNotifyOutcome.skippedOwnMessage;
      }
    }

    final canResolve = channelId != null && sequenceNumber != null;
    final notificationId = canResolve ? notificationIdFor(channelId, sequenceNumber) : null;
    final payload = NotificationPayload(channelId: channelId, sequenceNumber: sequenceNumber);

    var placeholderShown = false;
    if (placeholderFirst && canResolve) {
      try {
        await _presenter.showBell(fallback, id: notificationId, payload: payload);
        placeholderShown = true;
        AppLogger.i('NewMessageNotifier', 'Placeholder shown after ${stopwatch.elapsedMilliseconds}ms');
      } catch (error, stack) {
        AppLogger.w('NewMessageNotifier', 'Placeholder failed', error, stack);
      }
    }

    if (canResolve) {
      try {
        final message = await _resolve(channelId: channelId, sequenceNumber: sequenceNumber);
        final text = message.decryptedOtp;
        if (!message.decryptFailed && text != null && text.trim().isNotEmpty) {
          await _presenter.showOtp(OtpNotificationContent.fromMessage(message));
          AppLogger.i('NewMessageNotifier', 'OTP shown after ${stopwatch.elapsedMilliseconds}ms');
          return NewMessageNotifyOutcome.otpShown;
        }
      } catch (error, stack) {
        AppLogger.w(
          'NewMessageNotifier',
          'Resolve message failed after ${stopwatch.elapsedMilliseconds}ms',
          error,
          stack,
        );
      }
    }

    // Thông báo chung đã hiện từ đầu → giữ nguyên, không kêu lại.
    if (placeholderShown) return NewMessageNotifyOutcome.fallbackShown;

    await _presenter.showBell(fallback, id: notificationId, payload: payload);
    return NewMessageNotifyOutcome.fallbackShown;
  }
}
