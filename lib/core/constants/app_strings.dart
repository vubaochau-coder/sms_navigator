/// Hằng số chuỗi cần dùng trước khi cây l10n sẵn sàng (ví dụ `MaterialApp.title`).
/// Mọi chuỗi hiển thị khác nằm trong `lib/l10n/app_vi.arb`.
class AppStrings {
  AppStrings._();

  static const String appTitle = 'SMS Navigator';

  /// Tên thiết bị mặc định khi native không cho tên thật. Cần `const` (giá
  /// trị mặc định của event/state) nên không lấy được từ l10n — phải trùng
  /// `splashDefaultDeviceName` trong `app_vi.arb` (có test kiểm tra).
  static const String defaultDeviceName = 'Thiết bị của tôi';
}
