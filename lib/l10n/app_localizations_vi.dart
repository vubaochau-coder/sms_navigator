// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'OTP Relay';

  @override
  String get roleSelectionTitle => 'Chọn Chế Độ Hoạt Động';

  @override
  String get roleSelectionSubtitle =>
      'Ghép đôi và tự động chuyển tiếp OTP giữa Việt Nam và Malaysia';

  @override
  String get roleSenderTitle => 'Máy Gửi (Việt Nam)';

  @override
  String get roleSenderDesc =>
      'Điện thoại cắm SIM Viettel nhận SMS OTP và tự động chuyển tiếp ngầm.';

  @override
  String get roleReceiverTitle => 'Máy Nhận (Malaysia)';

  @override
  String get roleReceiverDesc =>
      'Nhận mã OTP qua Internet và hiển thị thông báo tức thì kèm nút sao chép.';

  @override
  String get pairingTitle => 'Ghép Đôi Thiết Bị';

  @override
  String get pairingSenderGuide =>
      'Hiển thị mã QR để thiết bị Máy Nhận quét và thiết lập kênh E2EE.';

  @override
  String get pairingReceiverGuide =>
      'Quét mã QR trên Máy Gửi để thiết lập kênh mã hóa E2EE.';

  @override
  String get senderDashboardTitle => 'Bảng Điều Khiển Máy Gửi';

  @override
  String get receiverDashboardTitle => 'Danh Sách OTP Nhận Được';

  @override
  String get statusOnline => 'Đang hoạt động';

  @override
  String get statusOffline => 'Đang tạm dừng';

  @override
  String get statusWaitingPair => 'Chưa ghép đôi';

  @override
  String get batteryOptimizationTitle => 'Tối ưu hóa Pin';

  @override
  String get batteryOptimizationDesc =>
      'Cho phép app chạy ngầm không bị hệ điều hành tắt để nhận SMS.';

  @override
  String get confirm => 'Xác nhận';

  @override
  String get cancel => 'Hủy bỏ';

  @override
  String get close => 'Đóng';

  @override
  String get copy => 'Sao chép';

  @override
  String get copiedToClipboard => 'Đã sao chép vào bộ nhớ tạm';

  @override
  String copiedWithLabel(String label, String value) {
    return 'Đã sao chép $label: $value';
  }

  @override
  String get success => 'Thành công';

  @override
  String get error => 'Lỗi';

  @override
  String get warning => 'Cảnh báo';

  @override
  String get info => 'Thông tin';

  @override
  String get pairingGenerateQr => 'Tạo mã QR ghép đôi';

  @override
  String get pairingScanQr => 'Quét mã QR';

  @override
  String get pairingSuccess => 'Ghép đôi thiết bị thành công!';

  @override
  String get pairingFailed => 'Ghép đôi thất bại. Vui lòng thử lại!';

  @override
  String get pairingQrExpired => 'Mã QR không hợp lệ hoặc đã hết hạn.';

  @override
  String get disconnect => 'Ngắt kết nối';

  @override
  String get disconnectSuccess => 'Đã hủy kết nối thành công';

  @override
  String get disconnectFailed => 'Không thể hủy kết nối';

  @override
  String get confirmRevokeSenderTitle => 'Hủy kết nối máy gửi?';

  @override
  String confirmRevokeSenderMessage(String name) {
    return 'Bạn có chắc chắn muốn ngắt kết nối với \"$name\"? Bạn sẽ không nhận được OTP từ thiết bị này nữa.';
  }

  @override
  String get confirmRevokeReceiverTitle => 'Hủy kết nối thiết bị?';

  @override
  String confirmRevokeReceiverMessage(String name) {
    return 'Bạn có chắc chắn muốn ngắt kết nối với \"$name\"? Thiết bị này sẽ không thể nhận OTP từ bạn nữa.';
  }

  @override
  String get relayEnabled => 'Đã kích hoạt dịch vụ chuyển tiếp';

  @override
  String get relayDisabled => 'Đã tạm dừng dịch vụ chuyển tiếp';

  @override
  String get relayModeOtpOnly => 'Chỉ chuyển tiếp mã OTP';

  @override
  String get relayModeAllSms => 'Chuyển tiếp tất cả SMS';

  @override
  String relayModeChanged(String mode) {
    return 'Đã chuyển sang chế độ: $mode';
  }

  @override
  String addWhitelistSuccess(String prefix) {
    return 'Đã thêm đầu số $prefix vào bộ lọc';
  }

  @override
  String removeWhitelistSuccess(String prefix) {
    return 'Đã xóa đầu số $prefix';
  }

  @override
  String get addWhitelistHint =>
      'Nhập đầu số hoặc tên đơn vị gửi (VD: VCB, BIDV, 1555)';

  @override
  String get otpListTitle => 'Lịch sử nhận OTP';

  @override
  String get otpListEmpty => 'Chưa có mã OTP nào được ghi nhận';

  @override
  String get otpDetailTitle => 'Chi tiết tin nhắn OTP';

  @override
  String get otpCopied => 'Đã sao chép mã OTP';

  @override
  String get filterByDate => 'Lọc theo ngày';

  @override
  String get groupByDevice => 'Gom nhóm theo thiết bị';

  @override
  String get senderDevice => 'Thiết bị gửi';

  @override
  String get receivedAt => 'Thời gian nhận';

  @override
  String get content => 'Nội dung';

  @override
  String get serverSettingsTitle => 'Cấu hình Server Backend';

  @override
  String serverSettingsSaved(String url) {
    return 'Đã lưu cấu hình server: $url';
  }

  @override
  String get serverSettingsFailed => 'Không thể lưu cấu hình. Thử lại sau.';

  @override
  String get navTabSms => 'SMS';

  @override
  String get navTabPairing => 'Ghép nối';

  @override
  String get pairingHubTitle => 'Ghép Nối Thiết Bị';

  @override
  String get pairingHubTabReceivers => 'Máy nhận';

  @override
  String get pairingHubTabSenders => 'Máy gửi';

  @override
  String get pairingHubReceiversDesc =>
      'Danh sách các máy đang nhận SMS của bạn';

  @override
  String get pairingHubSendersDesc => 'Danh sách các máy gửi SMS cho bạn';

  @override
  String get pairingHubCreateQr => 'Tạo mã QR';

  @override
  String get pairingHubScanQr => 'Quét mã';

  @override
  String get pairingHubAddNew => 'Thêm thiết bị ghép nối';

  @override
  String get pairingHubAddReceiver => 'Thêm máy nhận (Tạo mã QR)';

  @override
  String get pairingHubAddSender => 'Thêm máy gửi (Quét mã QR)';

  @override
  String get settingsAction => 'Cài đặt';

  @override
  String otpTodayWithDate(String date) {
    return 'Hôm nay, $date';
  }

  @override
  String get themeSwitchToLight => 'Chuyển sang nền sáng';

  @override
  String get themeSwitchToDark => 'Chuyển sang nền tối';

  @override
  String otpCopiedMessage(String otp) {
    return 'Đã sao chép mã OTP: $otp';
  }

  @override
  String get otpSmsNotification => 'THÔNG BÁO SMS';

  @override
  String get otpCopyAction => 'Sao chép mã';

  @override
  String get otpViewFullMessage => 'Xem toàn bộ tin nhắn';

  @override
  String otpEmptyInDate(String date) {
    return 'Không có mã OTP nào trong ngày $date';
  }

  @override
  String get otpEmptyGuide =>
      'Các tin nhắn OTP hoặc SMS được relay trong ngày này sẽ xuất hiện tại đây. Bạn có thể chọn ngày khác trên thanh lịch phía trên.';

  @override
  String otpFilterDateWithCount(String date, int count) {
    return 'Ngày: $date ($count tin)';
  }

  @override
  String get otpGroupByDevice => 'Nhóm theo máy';

  @override
  String get retry => 'Thử lại';

  @override
  String get refresh => 'Làm mới';

  @override
  String get done => 'Hoàn tất';

  @override
  String get errorOccurred => 'Có lỗi xảy ra';

  @override
  String get emptySendersTitle => 'Chưa kết nối máy gửi nào';

  @override
  String get emptySendersMessage =>
      'Thiết bị này chưa nhận OTP từ máy gửi nào. Vui lòng quét mã QR từ máy gửi để hoàn tất ghép đôi.';

  @override
  String get scanSenderQrAction => 'Quét mã QR ghép đôi';

  @override
  String get emptyReceiversTitle => 'Chưa có thiết bị nhận nào';

  @override
  String get emptyReceiversMessage =>
      'Hiện tại chưa có máy nhận nào ghép đôi với thiết bị này. Bấm nút bên dưới để tạo mã QR kết nối.';

  @override
  String get statusSending => 'Đang gửi';

  @override
  String get statusPaused => 'Đã tạm dừng';

  @override
  String get statusSenderMaintaining => 'Đang duy trì gửi';

  @override
  String get statusSenderPaused => 'Người gửi tạm dừng';

  @override
  String get pairedAt => 'Ghép đôi lúc';

  @override
  String get lastActiveAt => 'Hoạt động gần nhất';

  @override
  String get lastReceivedAt => 'Lần nhận gần nhất';

  @override
  String get allowSendingOtp => 'Cho phép gửi OTP';

  @override
  String get pauseSendingOtp => 'Tạm dừng gửi OTP';

  @override
  String get senderMaintainingDesc =>
      'Người gửi đang duy trì truyền tin. (Chỉ xem)';

  @override
  String get senderPausedDesc =>
      'Người gửi đang tạm dừng truyền tin. (Chỉ xem)';

  @override
  String get revokePairTooltip => 'Hủy ghép đôi';

  @override
  String get qrPairingTitle => 'Mã QR Ghép Đôi';

  @override
  String get qrPairingDesc =>
      'Dùng Thiết Bị Nhận để quét mã QR bên dưới, thiết lập kênh E2EE an toàn tức thì.';

  @override
  String get cannotGeneratePairingCode => 'Không thể tạo mã ghép đôi.';

  @override
  String get smsPermissionBannerWarning =>
      'Chưa cấp quyền đọc SMS — tính năng chuyển tiếp OTP đang tạm dừng.';

  @override
  String get openAppSettingsAction => 'Mở Cài Đặt';

  @override
  String get grantPermissionAction => 'Cấp Quyền';

  @override
  String get scannerTitle => 'Quét Mã Ghép Đôi';

  @override
  String get scannerAlignGuide =>
      'Căn chỉnh mã QR từ Máy Gửi vào giữa khung hình để hoàn tất ghép đôi';

  @override
  String get deviceSetupTitle => 'Thiết Lập Thiết Bị';

  @override
  String get deviceSetupGuide =>
      'Hoàn tất các bước dưới đây để máy luôn bắt được SMS OTP và chuyển tiếp ổn định, kể cả khi ứng dụng bị đóng.';

  @override
  String get stepSmsPermissionTitle => '1. Quyền đọc tin nhắn SMS';

  @override
  String get stepRequiredForSender => '(Bắt buộc với thiết bị gửi)';

  @override
  String get stepRequiredForReceiver => '(Bắt buộc với thiết bị nhận)';

  @override
  String get stepBatteryOptimizationTitle => '2. Miễn trừ tối ưu pin';

  @override
  String stepAutostartTitle(String oem) {
    return '3. Tự khởi chạy (Autostart) — $oem';
  }

  @override
  String get stepBackgroundTitle => '3. Cho phép chạy nền & tự khởi chạy';

  @override
  String get openAppDetailsAction => 'Mở Cài Đặt Ứng Dụng';

  @override
  String get grantPermissionStepAction => 'Cấp Quyền';

  @override
  String get requestBatteryOptimizationAction => 'Yêu Cầu Miễn Trừ';

  @override
  String get openAutostartAction => 'Mở Cài Đặt Autostart';

  @override
  String get openBackgroundAction => 'Mở Cài Đặt Chạy Nền';

  @override
  String get reopenSettingsAction => 'Mở Lại Cài Đặt';

  @override
  String get iHaveEnabledAction => 'Tôi Đã Bật';

  @override
  String get statusChecking => 'Đang kiểm tra...';

  @override
  String get statusCompleted => 'Đã hoàn tất';

  @override
  String get statusPendingConfirm => 'Đang chờ xác nhận';

  @override
  String get statusNotDone => 'Chưa thực hiện';

  @override
  String get permissionDialogTitle => 'Thiết lập quyền';

  @override
  String get permissionDialogMessage =>
      'Một số quyền quan trọng chưa được cấp, ứng dụng có thể sẽ không hoạt động chính xác.';

  @override
  String get dontRemindAgain => 'Không nhắc lại';

  @override
  String get goToSettings => 'Đi đến cài đặt';

  @override
  String get otpOriginalMessageTitle => 'Nội dung tin nhắn gốc:';

  @override
  String get otpNoContent => '[Không có nội dung]';

  @override
  String get otpCopyFullMessage => 'Sao chép toàn bộ tin nhắn';

  @override
  String get otpCopiedFullMessage => 'toàn bộ tin nhắn';

  @override
  String get otpAuthCodeTitle => 'MÃ XÁC THỰC (OTP)';

  @override
  String get otpLabel => 'mã OTP';
}
