import '../models/channel_event.dart';
import '../services/device_storage_service.dart';
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
  }) : _resolve = resolveIncomingMessage,
       _deviceStorage = deviceStorage,
       _presenter = presenter;

  final ResolveIncomingMessageUseCase _resolve;
  final DeviceStorageService _deviceStorage;
  final LocalNotificationPresenter _presenter;

  Future<NewMessageNotifyOutcome> handle(
    ChannelEvent event, {
    required BellNotificationContent fallback,
  }) async {
    final channelId = event.channelId;
    final sequenceNumber = event.sequenceNumber;

    final sender = event.senderDeviceId;
    if (sender != null) {
      final myDeviceId = await _deviceStorage.getDeviceId();
      if (myDeviceId != null && myDeviceId == sender) {
        return NewMessageNotifyOutcome.skippedOwnMessage;
      }
    }

    if (channelId != null && sequenceNumber != null) {
      try {
        final message = await _resolve(channelId: channelId, sequenceNumber: sequenceNumber);
        final text = message.decryptedOtp;
        if (!message.decryptFailed && text != null && text.trim().isNotEmpty) {
          await _presenter.showOtp(OtpNotificationContent.fromMessage(message));
          return NewMessageNotifyOutcome.otpShown;
        }
      } catch (error, stack) {
        AppLogger.w('NewMessageNotifier', 'Resolve message failed', error, stack);
      }
    }

    await _presenter.showBell(
      fallback,
      id: channelId != null && sequenceNumber != null
          ? notificationIdFor(channelId, sequenceNumber)
          : null,
      payload: NotificationPayload(channelId: channelId, sequenceNumber: sequenceNumber),
    );
    return NewMessageNotifyOutcome.fallbackShown;
  }
}
