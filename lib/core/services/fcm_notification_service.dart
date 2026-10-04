export 'impls/fcm_notification_service_impl.dart'
    show firebaseMessagingBackgroundHandler;

/// FCM chỉ là chuông (API spec §7, I5/N8):
/// - Data message KHÔNG chứa ciphertext/key — mất FCM vô hại vì app luôn
///   reconcile khi mở;
/// - Tap chuông → mở app → người dùng tự vào màn OTP hôm nay / màn kênh.
abstract class FcmNotificationService {
  Future<void> initialize();
  Future<void> syncToken();
  void dispose();
}
