import '../l10n/app_l10n.dart';
import '../ui/toast_utils.dart';
import '../utils/app_logger.dart';
import 'device_storage_service.dart';

/// Xử lý 401 tập trung (BACKLOG 3.2): `ApiClient` gọi [call] khi một request
/// bị từ chối vì device token.
///
/// **Không tự đăng ký lại.** Trước đây hàm này đăng ký lại với cùng
/// `device_id`; server giờ từ chối việc đó nếu không có token hiện tại của
/// thiết bị (409 `DEVICE_EXISTS`) vì đó chính là lỗ hổng chiếm thiết bị
/// (FLOW_AUDIT S1). 401 nghĩa là phiên của máy này đã mất: chỉ báo người dùng
/// mở lại app — Splash sẽ cho chọn khôi phục từ bản sao lưu hoặc thiết lập
/// như máy mới. Luôn trả `false` (không gửi lại request).
///
/// Báo tối đa một lần mỗi [notifyCooldown] để nhiều 401 liên tiếp không spam.
class DeviceSessionRecovery {
  DeviceSessionRecovery({
    required DeviceStorageService storage,
    DateTime Function()? clock,
    void Function(String message)? notifyFailure,
  }) : _storage = storage,
       _now = clock ?? DateTime.now,
       _notify = notifyFailure ?? ((message) => ToastUtils.showError(message));

  static const Duration notifyCooldown = Duration(seconds: 30);

  final DeviceStorageService _storage;
  final DateTime Function() _now;
  final void Function(String message) _notify;

  DateTime? _lastNotifiedAt;

  Future<bool> call() async {
    // Chưa từng đăng ký → không phải phiên hết hạn; Splash lo việc đăng ký.
    final token = await _storage.getDeviceToken();
    if (token == null || token.isEmpty) return false;

    final last = _lastNotifiedAt;
    if (last != null && _now().difference(last) < notifyCooldown) return false;
    _lastNotifiedAt = _now();

    AppLogger.w('DeviceSessionRecovery', '401 on an authenticated request — device session lost');
    _notify(AppL10n.current.sessionRecoveryFailed);
    return false;
  }
}
