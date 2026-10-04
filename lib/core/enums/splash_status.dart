/// Các giai đoạn / trạng thái trong quá trình khởi tạo tại Splash screen.
enum SplashStatus {
  initial,
  initializingServices,
  checkingIdentityKey,
  authenticatingDevice,
  registeringDevice,
  syncingChannels,
  ready,
  failure,
}
