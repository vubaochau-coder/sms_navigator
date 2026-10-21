/// Các giai đoạn / trạng thái trong quá trình khởi tạo tại Splash screen.
enum SplashStatus {
  initial,
  initializingServices,
  checkingIdentityKey,
  authenticatingDevice,

  /// Bản cài chưa đăng ký: chờ người dùng chọn "thiết lập mới" hay
  /// "khôi phục từ bản sao lưu" (BACKLOG 1.1).
  awaitingSetupChoice,
  registeringDevice,
  syncingChannels,
  ready,
  failure,
}
