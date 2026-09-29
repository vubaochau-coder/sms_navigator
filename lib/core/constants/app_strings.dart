class AppStrings {
  AppStrings._();

  static const String appTitle = 'OTP Relay';
  static const String roleSelectionTitle = 'Chọn Chế Độ Hoạt Động';
  static const String roleSelectionSubtitle = 'Ghép đôi và tự động chuyển tiếp OTP giữa Việt Nam và Malaysia';

  static const String roleSenderTitle = 'Máy Gửi (Việt Nam)';
  static const String roleSenderDesc = 'Điện thoại cắm SIM Viettel nhận SMS OTP và tự động chuyển tiếp ngầm.';

  static const String roleReceiverTitle = 'Máy Nhận (Malaysia)';
  static const String roleReceiverDesc = 'Nhận mã OTP qua Internet và hiển thị thông báo tức thì kèm nút sao chép.';

  static const String pairingTitle = 'Ghép Đôi Thiết Bị';
  static const String pairingSenderGuide = 'Quét mã QR hoặc nhập mã ghép đôi 6 số từ thiết bị Máy Nhận.';
  static const String pairingReceiverGuide = 'Nhập mã ghép đôi hiển thị trên Máy Gửi để thiết lập kênh mã hóa E2EE.';

  static const String senderDashboardTitle = 'Bảng Điều Khiển Máy Gửi';
  static const String receiverDashboardTitle = 'Danh Sách OTP Nhận Được';

  static const String statusOnline = 'Đang hoạt động';
  static const String statusOffline = 'Đang tạm dừng';
  static const String statusWaitingPair = 'Chưa ghép đôi';

  static const String batteryOptimizationTitle = 'Tối ưu hóa Pin';
  static const String batteryOptimizationDesc = 'Cho phép app chạy ngầm không bị hệ điều hành tắt để nhận SMS.';
}
