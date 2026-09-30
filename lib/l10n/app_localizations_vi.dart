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
}
