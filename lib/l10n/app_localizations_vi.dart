// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'SMS Navigator';

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
  String addWhitelistSuccess(String address) {
    return 'Đã thêm địa chỉ $address vào bộ lọc';
  }

  @override
  String removeWhitelistSuccess(String address) {
    return 'Đã xóa địa chỉ $address';
  }

  @override
  String get addWhitelistHint =>
      'Nhập đầu số hoặc brandname gửi tin (VD: VCB, BIDV, 1555). Địa chỉ được so khớp chính xác toàn phần, phân biệt hoa thường.';

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
  String get smsFilterAll => 'Tất cả';

  @override
  String get smsFilterSent => 'SMS Gửi Đi';

  @override
  String get smsFilterReceived => 'SMS Nhận Được';

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
  String get deviceProfileTitle => 'Thông tin & Thiết lập thiết bị';

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

  @override
  String get smsRestrictedGuideTitle =>
      'Nếu việc cấp quyền không thành công, thực hiện theo hướng dẫn sau:';

  @override
  String get smsRestrictedGuideStep1Prefix => '- Bấm vào ';

  @override
  String get smsRestrictedGuideStep1Action => '\"Cài đặt ứng dụng\"';

  @override
  String get smsRestrictedGuideStep1Suffix =>
      ' (góc trên phải chọn 3 chấm ⋮ ➔ Cho phép cài đặt bị hạn chế).';

  @override
  String get smsRestrictedGuideStep2Prefix => '- Quay lại ';

  @override
  String get smsRestrictedGuideStep2Action => 'Quyền ứng dụng';

  @override
  String get smsRestrictedGuideStep2Suffix => ' ➔ Bật quyền SMS (Tin nhắn).';

  @override
  String get whitelistSettingsTitle => 'Bộ lọc tin nhắn gửi';

  @override
  String get whitelistAllAddressesToggle => 'Nhận từ mọi địa chỉ';

  @override
  String get whitelistAllAddressesDesc =>
      'SMS thường từ mọi đầu số được chuyển tiếp. Riêng OTP bắt buộc phải liệt kê từng địa chỉ bên dưới.';

  @override
  String get whitelistExplicitDesc =>
      'Chỉ SMS từ các địa chỉ trong danh sách được chuyển tiếp. Danh sách trống nghĩa là chặn tất cả.';

  @override
  String get whitelistOtpSectionCaption => 'Địa chỉ được cấp quyền gửi OTP';

  @override
  String get whitelistEmptyListHint =>
      'Chưa có địa chỉ nào. Thêm đầu số hoặc brandname để bắt đầu.';

  @override
  String get whitelistEmptyWarningTitle => 'Chưa cấu hình bộ lọc gửi';

  @override
  String get whitelistEmptyWarningMessage =>
      'Tin nhắn SMS đang tạm dừng chuyển tiếp để bảo vệ an toàn dữ liệu. Thêm địa chỉ bạn muốn chuyển tiếp.';

  @override
  String get whitelistConfigureAction => 'Cấu hình ngay';

  @override
  String get addWhitelistDialogTitle => 'Thêm địa chỉ';

  @override
  String whitelistDuplicateError(String address) {
    return 'Địa chỉ \"$address\" đã có trong danh sách';
  }

  @override
  String get whitelistEmptyAddressError => 'Địa chỉ không được để trống';

  @override
  String get whitelistLoadFailed => 'Không thể đọc cấu hình bộ lọc';

  @override
  String get whitelistSaveFailed => 'Không thể lưu cấu hình bộ lọc';

  @override
  String get whitelistRemoveAction => 'Xóa địa chỉ';

  @override
  String get saveQrImageAction => 'Lưu ảnh QR';

  @override
  String get qrImageExportSuccess => 'Đã lưu ảnh mã QR vào thư viện máy';

  @override
  String get qrImageExportFailed =>
      'Không thể lưu ảnh mã QR. Vui lòng thử lại.';

  @override
  String get qrImageExportPermissionDenied =>
      'Chưa được cấp quyền lưu ảnh vào thư viện';

  @override
  String get qrImageExportNoQr => 'Chưa có mã QR ghép đôi để lưu';

  @override
  String get scannerPickFromGallery => 'Chọn ảnh từ thư viện';

  @override
  String get scannerNoQrFound => 'Không tìm thấy mã QR trong ảnh đã chọn';

  @override
  String get scannerUnsupportedQr =>
      'Mã QR này không được SMS Navigator hỗ trợ';

  @override
  String get pairingLinkedChip => 'Đã kết nối — Máy B đã quét mã';

  @override
  String get deeplinkPairingTitle => 'Ghép đôi từ mã QR';

  @override
  String get deeplinkPairingInProgress => 'Đang ghép nối...';

  @override
  String get deeplinkPairingSuccess => 'Đã ghép nối thành công';

  @override
  String get deeplinkPairingFailed => 'Ghép nối không thành công';

  @override
  String get pairingQrNoSecretHint =>
      'Mã QR không chứa mật khẩu — nếu ảnh bị lộ, kẻ khác vẫn không đọc được tin nhắn của bạn.';

  @override
  String get pairingDeletePhotoReminder =>
      'Đã ghép nối thành công. Nhớ xóa ảnh QR trong thư viện và cuộc trò chuyện đã gửi.';

  @override
  String get splashSubtitle => 'Ghép đôi và đồng bộ SMS an toàn';

  @override
  String get splashInitializingApp => 'Đang khởi tạo ứng dụng...';

  @override
  String get splashInitializingServices => 'Đang khởi tạo các dịch vụ...';

  @override
  String get splashCheckingIdentityKey =>
      'Đang kiểm tra khóa định danh thiết bị...';

  @override
  String get splashAuthenticatingDevice =>
      'Đang xác thực thiết bị với máy chủ...';

  @override
  String get splashRegisteringDevice => 'Đang đăng ký thiết bị mới...';

  @override
  String get splashSyncingChannels => 'Đang đồng bộ dữ liệu kênh...';

  @override
  String get splashReady => 'Sẵn sàng!';

  @override
  String splashConnectionError(String error) {
    return 'Không thể kết nối hoặc xác thực thiết bị: $error';
  }

  @override
  String get splashRetry => 'Thử lại';

  @override
  String get splashSkipOffline => 'Bỏ qua & Vào chế độ ngoại tuyến';

  @override
  String get splashDefaultDeviceName => 'Thiết bị của tôi';

  @override
  String get smsPageTitle => 'SMS';

  @override
  String get smsRefreshTooltip => 'Làm mới';

  @override
  String smsEmptyInDate(String date) {
    return 'Ngày $date chưa có tin nhắn SMS nào';
  }

  @override
  String smsDailyMessageCount(int count) {
    return 'Danh sách tin nhắn trong ngày ($count)';
  }

  @override
  String get smsDecryptError => 'Không giải mã được tin này';

  @override
  String smsChannelPrefix(String channelName, String time) {
    return 'Kênh: $channelName · $time';
  }

  @override
  String get smsCopyTooltip => 'Sao chép';

  @override
  String smsCopied(String otp) {
    return 'Đã sao chép: $otp';
  }

  @override
  String get smsLoadError =>
      'Không tải được tin nhắn SMS của ngày này. Kiểm tra kết nối và thử lại.';

  @override
  String get smsLoadErrorTitle => 'Lỗi tải tin nhắn';

  @override
  String get channelPageTitle => 'Kênh';

  @override
  String get channelRenameDeviceTooltip => 'Đổi tên thiết bị';

  @override
  String get channelEmptyMessage =>
      'Bạn chưa tham gia kênh nào.\nTạo kênh mới hoặc quét mã mời.';

  @override
  String get channelOwnedEmptyMessage =>
      'Bạn chưa tạo kênh nào.\nNhấn nút \"Tạo kênh\" bên dưới.';

  @override
  String get channelJoinedEmptyMessage =>
      'Bạn chưa tham gia kênh nào.\nQuét mã QR mời để tham gia kênh.';

  @override
  String get channelOwnedSectionTitle => 'Kênh của bạn';

  @override
  String get channelJoinedSectionTitle => 'Kênh bạn tham gia';

  @override
  String get channelCreateAction => 'Tạo kênh';

  @override
  String get channelCreateDialogTitle => 'Tạo kênh mới';

  @override
  String get channelNameLabel => 'Tên kênh';

  @override
  String get channelNameHint => 'Ví dụ: Kênh nhà';

  @override
  String get channelCreateConfirm => 'Tạo';

  @override
  String get channelRenameDialogTitle => 'Đổi tên thiết bị';

  @override
  String get channelDeviceNameLabel => 'Tên hiển thị';

  @override
  String get channelDeviceNameHint => 'Ví dụ: Pixel 8 của Minh';

  @override
  String get channelSaveConfirm => 'Lưu';

  @override
  String channelOwnerSubtitle(int count, int epoch) {
    return '$count thành viên · epoch $epoch';
  }

  @override
  String channelMemberSubtitle(String ownerName, int count) {
    return 'Máy chủ: $ownerName · $count thành viên';
  }

  @override
  String get joinPageTitle => 'Tham gia kênh';

  @override
  String get joinInvalidInviteTitle => 'Mã mời không hợp lệ';

  @override
  String get joinInvalidInviteMessage =>
      'Mã QR này không đúng định dạng. Hãy xin Owner một mã mời mới.';

  @override
  String get joinExpiredInviteTitle => 'Mã mời đã hết hạn';

  @override
  String get joinExpiredInviteMessage =>
      'Mã mời chỉ có hiệu lực 10 phút. Hãy xin Owner một mã mời mới.';

  @override
  String get joinIdleEmptyMessage => 'Chưa gửi yêu cầu tham gia nào';

  @override
  String get joinReenterInviteAction => 'Nhập lại mã mời';

  @override
  String joinChannelLabel(String channelName) {
    return 'Kênh: $channelName';
  }

  @override
  String joinOwnerLabel(String ownerName) {
    return 'Chủ kênh: $ownerName';
  }

  @override
  String get joinDeviceNameLabel => 'Tên thiết bị của bạn';

  @override
  String get joinDismissAction => 'Để sau';

  @override
  String get joinSendRequestAction => 'Gửi yêu cầu kết nối';

  @override
  String get joinWaitingApprovalTitle => 'Đang chờ duyệt';

  @override
  String get joinWaitingApprovalMessage => 'Yêu cầu đã được gửi tới máy chủ.';

  @override
  String joinWaitingApprovalChannelMessage(String channelName) {
    return 'Đã gửi yêu cầu tham gia \"$channelName\". Chờ máy chủ (Owner) duyệt.';
  }

  @override
  String get joinCancelRequestAction => 'Hủy yêu cầu';

  @override
  String get joinCancelConfirmTitle => 'Hủy yêu cầu?';

  @override
  String get joinCancelConfirmMessage =>
      'Yêu cầu tham gia kênh sẽ bị hủy. Owner sẽ không thấy yêu cầu này nữa.';

  @override
  String get joinContinueWaitingAction => 'Tiếp tục chờ';

  @override
  String get channelDetailTitle => 'Chi tiết kênh';

  @override
  String get channelDetailInviteTooltip => 'Mời thành viên';

  @override
  String channelDetailOwnerServer(String ownerName) {
    return 'Máy chủ (Owner): $ownerName';
  }

  @override
  String channelDetailMemberCount(int count) {
    return '$count thành viên';
  }

  @override
  String channelDetailCurrentEpoch(int epoch) {
    return 'Epoch hiện tại: $epoch';
  }

  @override
  String channelDetailPendingRequestsTitle(int count) {
    return 'Yêu cầu chờ duyệt ($count)';
  }

  @override
  String get channelDetailApproveTooltip => 'Duyệt';

  @override
  String get channelDetailRejectTooltip => 'Từ chối';

  @override
  String get channelDetailApproveDialogTitle => 'Duyệt thành viên?';

  @override
  String channelDetailApproveDialogMessage(String deviceName) {
    return 'Duyệt \"$deviceName\" sẽ tự động xoay khóa kênh và cấp khóa mới cho mọi thành viên.';
  }

  @override
  String get channelDetailApproveConfirm => 'Duyệt';

  @override
  String get channelDetailRejectDialogTitle => 'Từ chối yêu cầu?';

  @override
  String channelDetailRejectDialogMessage(String deviceName) {
    return 'Từ chối \"$deviceName\"? Mã QR đã dùng cho yêu cầu này sẽ không còn hiệu lực.';
  }

  @override
  String get channelDetailRejectConfirm => 'Từ chối';

  @override
  String channelDetailMembersTitle(int count) {
    return 'Thành viên ($count)';
  }

  @override
  String channelDetailMemberJoinedEpoch(int epoch) {
    return 'Tham gia epoch $epoch';
  }

  @override
  String get channelDetailMemberRevokedStatus => 'Đã thu hồi';

  @override
  String get channelDetailMemberOwner => 'Owner';

  @override
  String get channelDetailRevokeTooltip => 'Thu hồi';

  @override
  String get channelDetailRevokeDialogTitle => 'Thu hồi thành viên?';

  @override
  String channelDetailRevokeDialogMessage(String deviceName) {
    return 'Thu hồi \"$deviceName\" là hành động vĩnh viễn. Khóa kênh sẽ được xoay ngay để member này không đọc được tin mới.';
  }

  @override
  String get channelDetailRevokeConfirm => 'Thu hồi';

  @override
  String get channelDetailInviteSheetTitle => 'Mời thành viên';

  @override
  String channelDetailInviteQrExpiresIn(String time) {
    return 'Mã QR hết hạn sau: $time';
  }

  @override
  String get channelDetailInviteQrExpired =>
      'Mã QR đã hết hạn. Hãy nhấn tạo lại mã bên dưới.';

  @override
  String get channelDetailInviteCreatingQr => 'Đang tạo mã mời...';

  @override
  String get channelDetailInviteHint =>
      '• Người tham gia dùng ứng dụng quét mã QR này để gửi yêu cầu.\n• Mỗi mã QR chỉ có hiệu lực 1 lần trong vòng 10 phút.\n• Mã không chứa mật khẩu hay dữ liệu nhạy cảm.';

  @override
  String get channelDetailInviteRegenerate => 'Tạo lại mã';

  @override
  String get channelDetailInviteCopySuccess => 'Đã sao chép liên kết mời';

  @override
  String get channelDetailInviteCopyLink => 'Sao chép link';

  @override
  String get channelDetailInviteSaveQr => 'Lưu mã QR';

  @override
  String get channelDetailInviteSaveQrSuccess =>
      'Đã lưu mã QR vào thư viện ảnh';

  @override
  String get channelDetailInviteSaveQrFailed =>
      'Không thể lưu mã QR. Vui lòng thử lại sau.';

  @override
  String get channelDetailInviteSaveQrPermissionDenied =>
      'Ứng dụng cần quyền truy cập ảnh để lưu mã QR';

  @override
  String get channelDetailInviteCreateAction => 'Tạo mã mời QR';

  @override
  String channelPendingRequestsHeader(int count) {
    return 'Yêu cầu đang chờ duyệt ($count)';
  }

  @override
  String get channelPendingBadge => 'Đang chờ duyệt';

  @override
  String get channelCancelRequestSuccess => 'Đã hủy yêu cầu tham gia kênh';

  @override
  String get channelCancelRequestFailed =>
      'Không hủy được yêu cầu. Thử lại sau.';

  @override
  String get updateDialogTitle => 'Có phiên bản mới';

  @override
  String get updateNowButton => 'Cập nhật ngay';

  @override
  String get updateLaterButton => 'Để sau';

  @override
  String get updateForceNotice => 'Bắt buộc cập nhật để tiếp tục sử dụng';

  @override
  String get updateMissingUrlMessage => 'Chưa có liên kết tải phiên bản mới';

  @override
  String get updateInvalidUrlMessage => 'Liên kết tải không hợp lệ';

  @override
  String get updateLaunchErrorMessage => 'Không thể mở liên kết tải';

  @override
  String get networkRequestCancelled => 'Yêu cầu mạng đã bị hủy bỏ.';

  @override
  String networkConnectTimeout(int seconds) {
    return 'Kết nối tới máy chủ quá thời gian chờ (${seconds}s).';
  }

  @override
  String networkTransferTimeout(int seconds) {
    return 'Thời gian truyền dữ liệu với máy chủ quá hạn (${seconds}s).';
  }

  @override
  String get networkUnauthorized =>
      'Phiên xác thực thiết bị không hợp lệ hoặc đã hết hạn (401).';

  @override
  String networkServerError(String status) {
    return 'Máy chủ trả về lỗi (HTTP $status).';
  }

  @override
  String networkUnreachable(String detail) {
    return 'Không thể kết nối tới máy chủ: $detail';
  }

  @override
  String get networkOffline =>
      'Không kết nối được máy chủ. Kiểm tra mạng và thử lại.';

  @override
  String get notificationChannelDescription =>
      'Chuông báo có yêu cầu duyệt / tin nhắn SMS mới / thay đổi kênh';

  @override
  String get notificationDefaultBody =>
      'Có sự kiện mới trong kênh. Mở app để xem.';

  @override
  String get notificationJoinRequestTitle => 'Yêu cầu tham gia kênh';

  @override
  String notificationJoinRequestBody(String requesterName, String channelName) {
    return '$requesterName muốn tham gia kênh \"$channelName\".';
  }

  @override
  String notificationJoinRequestBodyNoChannel(String requesterName) {
    return '$requesterName muốn tham gia kênh.';
  }

  @override
  String get notificationJoinRequestBodyGeneric =>
      'Có thiết bị mới xin tham gia. Mở app để duyệt.';

  @override
  String get notificationApprovedTitle => 'Yêu cầu đã được duyệt';

  @override
  String notificationApprovedBody(String channelName) {
    return 'Bạn đã được thêm vào kênh \"$channelName\". Mở app để xem tin nhắn SMS.';
  }

  @override
  String get notificationApprovedBodyGeneric =>
      'Bạn đã được thêm vào kênh. Mở app để bắt đầu nhận tin nhắn SMS.';

  @override
  String get notificationRevokedTitle => 'Quyền truy cập đã bị thu hồi';

  @override
  String notificationRevokedBody(String channelName) {
    return 'Bạn không còn quyền truy cập kênh \"$channelName\".';
  }

  @override
  String get notificationRevokedBodyGeneric =>
      'Bạn không còn quyền truy cập một kênh.';

  @override
  String get notificationNewMessageTitle => 'Tin nhắn SMS mới';

  @override
  String notificationNewMessageBody(String channelName) {
    return 'Có tin nhắn SMS mới từ kênh \"$channelName\". Chạm để xem.';
  }

  @override
  String get notificationNewMessageBodyGeneric =>
      'Có tin nhắn SMS mới vừa được chia sẻ. Chạm để xem.';

  @override
  String notificationOtpTitle(String code) {
    return 'Mã OTP: $code';
  }

  @override
  String get notificationCopyAction => 'Sao chép';

  @override
  String get relativeJustNow => 'Vừa xong';

  @override
  String relativeMinutesAgo(int count) {
    return '$count phút trước';
  }

  @override
  String relativeHoursAgo(int count) {
    return '$count giờ trước';
  }

  @override
  String relativeYesterdayAt(String time) {
    return 'Hôm qua $time';
  }

  @override
  String relativeDaysAgo(int count) {
    return '$count ngày trước';
  }

  @override
  String get qrUnsupportedFormat =>
      'Mã QR không được hỗ trợ. Hãy quét mã mời từ SMS Navigator.';

  @override
  String get qrUpdateRequired =>
      'Mã này cần phiên bản SMS Navigator mới hơn. Hãy cập nhật ứng dụng.';

  @override
  String get qrCheckFailed =>
      'Không thể kiểm tra mã kết nối. Vui lòng thử lại sau.';

  @override
  String get qrNotFound =>
      'Không tìm thấy mã mời. Hãy kiểm tra lại hoặc xin Chủ kênh mã mới.';

  @override
  String get qrRateLimited =>
      'Bạn thử quá nhiều lần. Vui lòng đợi một lát rồi thử lại.';

  @override
  String get qrEntryTitle => 'Mã kết nối';

  @override
  String get qrEntryChecking => 'Đang kiểm tra mã kết nối…';

  @override
  String get qrEntryCheckFailedShort => 'Không thể kiểm tra mã kết nối.';

  @override
  String get joinErrorAlreadyPending =>
      'Bạn đã có yêu cầu tham gia kênh này đang chờ duyệt.';

  @override
  String get joinErrorAlreadyMember =>
      'Thiết bị của bạn đã là thành viên của kênh này.';

  @override
  String get joinErrorExpired =>
      'Mã mời đã hết hạn. Hãy xin Chủ kênh một mã mời mới.';

  @override
  String get joinErrorUsed =>
      'Mã mời đã được sử dụng. Hãy xin Chủ kênh một mã mời mới.';

  @override
  String get joinErrorChannelArchived =>
      'Kênh này đã bị lưu trữ, không thể tham gia.';

  @override
  String get joinClaimFailed =>
      'Không gửi được yêu cầu. Kiểm tra kết nối và thử lại.';

  @override
  String get joinClaimFailedRetry =>
      'Không gửi được yêu cầu. Vui lòng thử lại sau.';

  @override
  String get joinChannelFallbackName => 'kênh';

  @override
  String joinRequestSent(String channelName) {
    return 'Đã gửi yêu cầu tham gia $channelName';
  }

  @override
  String get joinLoadingChannelInfo => 'Đang tải thông tin kênh...';

  @override
  String get joinYourDeviceFallback => 'Thiết bị của bạn';

  @override
  String get back => 'Quay lại';

  @override
  String copiedLabel(String label) {
    return 'Đã sao chép $label';
  }

  @override
  String get statusPending => 'Đang chờ';

  @override
  String get channelLoadFailed =>
      'Không tải được danh sách kênh. Kiểm tra kết nối và thử lại.';

  @override
  String get channelCreateFailed => 'Không tạo được kênh. Thử lại sau.';

  @override
  String get deviceRenameFailed => 'Không đổi được tên thiết bị. Thử lại sau.';

  @override
  String get channelDetailLoadFailed =>
      'Không tải được chi tiết kênh. Kiểm tra kết nối và thử lại.';

  @override
  String channelDetailApproved(String deviceName) {
    return 'Đã duyệt $deviceName.';
  }

  @override
  String get channelDetailApproveConflict =>
      'Không duyệt được: trạng thái kênh đã thay đổi. Danh sách đã được làm mới, thử lại.';

  @override
  String channelDetailRejected(String deviceName) {
    return 'Đã từ chối $deviceName.';
  }

  @override
  String get channelDetailRejectFailed =>
      'Không từ chối được: yêu cầu có thể đã được xử lý.';

  @override
  String get channelDetailRevoked => 'Đã thu hồi thành viên và xoay khóa kênh.';

  @override
  String get channelDetailRevokeConflict =>
      'Không thu hồi được: trạng thái kênh đã thay đổi. Thử lại.';

  @override
  String get channelInviteCreateFailed => 'Không tạo được mã mời. Thử lại sau.';

  @override
  String get whitelistSectionTitle => 'Bộ lọc tin nhắn (White-list)';

  @override
  String get whitelistConfigureButton => 'Cấu hình';

  @override
  String get whitelistSectionOwnerDesc =>
      'Thiết lập danh sách số điện thoại/Brandname được phép chuyển tiếp tin nhắn SMS và OTP qua kênh này.';

  @override
  String get whitelistSectionMemberDesc =>
      'Kênh này được bảo vệ bởi bộ lọc của Chủ kênh. Tin nhắn SMS sẽ được chuyển tiếp theo cấu hình bảo mật đã duyệt.';

  @override
  String whitelistVersionLabel(int version) {
    return 'Phiên bản bộ lọc: v$version';
  }

  @override
  String whitelistFilterTitle(String channelName) {
    return 'Bộ lọc: $channelName';
  }

  @override
  String get whitelistMissingChannelKey =>
      'Không tìm thấy khóa bảo mật kênh để mã hóa';

  @override
  String get whitelistConflict =>
      'Cấu hình đã thay đổi trên thiết bị khác. Vui lòng tải lại.';

  @override
  String whitelistSaveRequiresNetwork(String detail) {
    return 'Không thể lưu cấu hình (bắt buộc kết nối mạng): $detail';
  }

  @override
  String get whitelistSaveOffline =>
      'Không có kết nối mạng. Không thể lưu cấu hình bộ lọc.';

  @override
  String get relayLogTitle => 'Nhật ký tiếp nhận SMS';

  @override
  String get relayLogDescription =>
      'Mỗi SMS tới sẽ được ghi lại tại đây kèm lý do bị chặn (nếu không relay được).';

  @override
  String get relayLogEmpty => 'Chưa có SMS nào được ghi nhận.';

  @override
  String get relayLogUnknownSender => '(không rõ số gửi)';

  @override
  String relayLogDetected(String otp) {
    return 'Nội dung phát hiện: $otp';
  }

  @override
  String get deviceRenameLoading => 'Đang cập nhật tên thiết bị...';

  @override
  String get deviceRenameSuccess => 'Đã cập nhật tên thiết bị';

  @override
  String get deviceResetLoading => 'Đang xóa dữ liệu thiết bị...';

  @override
  String get deviceResetSuccess => 'Đã xóa dữ liệu thiết bị';

  @override
  String get deviceResetFailed =>
      'Không thể xóa dữ liệu thiết bị. Thử lại sau.';

  @override
  String get deviceResetDialogTitle => 'Xóa dữ liệu thiết bị?';

  @override
  String get deviceResetDialogMessage =>
      'Toàn bộ mã định danh, token xác thực và cấu hình trên thiết bị này sẽ bị xóa hoàn toàn khỏi máy.\n\nỨng dụng sẽ được khởi động lại từ đầu để bạn đăng ký mới.';

  @override
  String get deviceResetConfirm => 'Xóa dữ liệu';

  @override
  String get deviceResetTitle => 'Xóa dữ liệu thiết bị';

  @override
  String get deviceResetSubtitle =>
      'Xóa mã định danh, token và khôi phục cài đặt gốc';

  @override
  String get devicePreferencesTitle => 'CÀI ĐẶT & TÙY CHỌN';

  @override
  String get themeModeLabel => 'Chế độ hiển thị';

  @override
  String get themeSystem => 'Hệ thống';

  @override
  String get themeLight => 'Sáng';

  @override
  String get themeDark => 'Tối';

  @override
  String get deviceSetupYourDevice => 'thiết bị của bạn';

  @override
  String get deviceHealthTitle => 'TÌNH TRẠNG THIẾT BỊ';

  @override
  String get deviceHealthReady => 'Sẵn sàng';

  @override
  String get deviceHealthNeedsAttention => 'Cần chú ý';

  @override
  String get deviceHealthSmsPermission => 'Quyền đọc SMS';

  @override
  String get deviceHealthGranted => 'Đã cấp quyền';

  @override
  String get deviceHealthNotGranted => 'Chưa cấp quyền';

  @override
  String get deviceHealthGrantNow => 'Cấp ngay';

  @override
  String get deviceHealthBackground => 'Chạy ngầm & Tối ưu pin';

  @override
  String get deviceHealthBatteryUnrestricted => 'Đã tắt hạn chế pin';

  @override
  String get deviceHealthBatteryRestricted => 'Có thể bị hệ điều hành tắt';

  @override
  String get deviceHealthOemDetails =>
      'Chi tiết thiết lập thiết bị & cài đặt OEM';

  @override
  String get deviceIdUnknown => 'Chưa xác định';

  @override
  String get deviceIdCopied => 'Đã sao chép ID thiết bị';

  @override
  String get scanInviteTooltip => 'Quét mã mời';

  @override
  String get scannerPasteAction => 'Dán mã';

  @override
  String get scannerClipboardEmpty => 'Bộ nhớ tạm không có mã nào để dán.';

  @override
  String get scannerCameraPermissionRequired =>
      'Ứng dụng cần quyền truy cập máy ảnh để quét mã QR';

  @override
  String scannerCameraStartFailed(String detail) {
    return 'Không thể khởi động máy ảnh: $detail';
  }

  @override
  String splashServerError(String status) {
    return 'Máy chủ đang gặp sự cố (HTTP $status). Vui lòng thử lại sau.';
  }

  @override
  String get splashStartupFailed =>
      'Đã xảy ra sự cố trong quá trình khởi động hệ thống. Vui lòng thử lại.';

  @override
  String get backupSectionTitle => 'SAO LƯU & KHÔI PHỤC';

  @override
  String get backupExportTitle => 'Tạo bản sao lưu';

  @override
  String get backupExportSubtitle =>
      'Lưu danh tính và khoá kênh ra file .smsnav để cài lại app hoặc chuyển máy';

  @override
  String get backupPassphraseTitle => 'Đặt mật khẩu cho bản sao lưu';

  @override
  String get backupPassphraseMessage =>
      'Bản sao lưu được mã hoá bằng mật khẩu này. Quên mật khẩu là không mở được file — hãy cất ở nơi an toàn.';

  @override
  String get backupExportWarning =>
      'File chứa khoá giải mã mọi tin nhắn của bạn. Đừng gửi file kèm mật khẩu cho người khác.';

  @override
  String get backupPassphraseLabel => 'Mật khẩu';

  @override
  String get backupPassphraseConfirmLabel => 'Nhập lại mật khẩu';

  @override
  String backupPassphraseTooShort(int min) {
    return 'Tối thiểu $min ký tự';
  }

  @override
  String get backupPassphraseMismatch => 'Mật khẩu nhập lại không khớp';

  @override
  String get backupShowPassphrase => 'Hiện mật khẩu';

  @override
  String get backupHidePassphrase => 'Ẩn mật khẩu';

  @override
  String get backupExportConfirm => 'Tạo & lưu file';

  @override
  String get backupExporting => 'Đang mã hoá bản sao lưu…';

  @override
  String backupExportSuccess(String fileName) {
    return 'Đã lưu $fileName';
  }

  @override
  String get backupRestoreTitle => 'Khôi phục từ bản sao lưu';

  @override
  String get backupRestoreIntro =>
      'Chọn file .smsnav đã tạo trên máy cũ rồi nhập mật khẩu. Máy này sẽ dùng lại đúng danh tính, các kênh và khoá cũ.';

  @override
  String get backupRestoreOldDeviceWarning =>
      'Sau khi khôi phục, đừng dùng app trên máy cũ nữa — hai máy chung một danh tính sẽ tranh nhau nhận thông báo và relay SMS.';

  @override
  String get backupPickFile => 'Chọn file sao lưu';

  @override
  String get backupFileSelected => 'Đã chọn file sao lưu';

  @override
  String get backupChangeFile => 'Chọn file khác';

  @override
  String get backupRestoreAction => 'Khôi phục';

  @override
  String get backupRestoring => 'Đang giải mã và khôi phục…';

  @override
  String backupRestoreSuccess(int count) {
    return 'Đã khôi phục danh tính và khoá của $count kênh';
  }

  @override
  String get backupErrorWrongPassphrase =>
      'Sai mật khẩu, hoặc file đã bị chỉnh sửa.';

  @override
  String get backupErrorInvalidFile =>
      'File này không phải bản sao lưu SMS Navigator hợp lệ.';

  @override
  String get backupErrorUnsupportedVersion =>
      'Bản sao lưu được tạo bởi phiên bản app mới hơn. Hãy cập nhật app rồi thử lại.';

  @override
  String get backupErrorIncomplete => 'Bản sao lưu thiếu dữ liệu danh tính.';

  @override
  String get backupErrorNotRegistered =>
      'Thiết bị chưa đăng ký — chưa có gì để sao lưu.';

  @override
  String get backupErrorStorage =>
      'Không đọc/ghi được file. Thử lại hoặc chọn vị trí khác.';

  @override
  String get splashSetupChoiceTitle => 'Bạn muốn bắt đầu thế nào?';

  @override
  String get splashSetupNewDevice => 'Thiết lập thiết bị mới';

  @override
  String get splashSetupNewDeviceSubtitle => 'Tạo danh tính mới cho máy này';

  @override
  String get splashSetupRestore => 'Khôi phục từ bản sao lưu';

  @override
  String get splashSetupRestoreSubtitle => 'Dùng file .smsnav từ máy cũ';

  @override
  String get channelDetailMoreTooltip => 'Tùy chọn kênh';

  @override
  String get channelRenameAction => 'Đổi tên kênh';

  @override
  String get channelRenameConfirm => 'Lưu';

  @override
  String channelRenameSuccess(String channelName) {
    return 'Đã đổi tên kênh thành \"$channelName\".';
  }

  @override
  String get channelRenameFailed =>
      'Không đổi được tên kênh. Vui lòng thử lại.';

  @override
  String get channelLeaveAction => 'Rời kênh';

  @override
  String get channelLeaveConfirmTitle => 'Rời kênh này?';

  @override
  String channelLeaveConfirmMessage(String channelName) {
    return 'Bạn sẽ không nhận và không xem được tin nhắn của \"$channelName\" nữa. Muốn quay lại phải xin Chủ kênh mã mời mới.';
  }

  @override
  String channelLeaveSuccess(String channelName) {
    return 'Đã rời kênh \"$channelName\".';
  }

  @override
  String get channelLeaveFailed => 'Không rời được kênh. Vui lòng thử lại.';

  @override
  String get channelArchiveAction => 'Giải tán kênh';

  @override
  String get channelArchiveConfirmTitle => 'Giải tán kênh?';

  @override
  String channelArchiveConfirmMessage(String channelName) {
    return 'Kênh \"$channelName\" sẽ bị xoá khỏi mọi thành viên, tin nhắn cũ không còn xem được và SMS sẽ ngừng chuyển tiếp. Không thể hoàn tác.';
  }

  @override
  String channelArchiveSuccess(String channelName) {
    return 'Đã giải tán kênh \"$channelName\".';
  }

  @override
  String get channelArchiveFailed =>
      'Không giải tán được kênh. Vui lòng thử lại.';

  @override
  String get requestHistoryAction => 'Lịch sử yêu cầu';

  @override
  String get requestHistoryTitle => 'Lịch sử yêu cầu kết nối';

  @override
  String get requestHistoryEmpty => 'Chưa có yêu cầu nào được xử lý.';

  @override
  String get requestHistoryLoadMore => 'Xem thêm';

  @override
  String get requestHistoryLoadFailed => 'Không tải được lịch sử yêu cầu.';

  @override
  String get requestHistoryRetry => 'Thử lại';

  @override
  String get requestStatusApproved => 'Đã duyệt';

  @override
  String get requestStatusRejected => 'Đã từ chối';

  @override
  String get requestStatusCancelled => 'Đã huỷ';

  @override
  String get backupReminderTitle => 'Chưa sao lưu khóa kênh';

  @override
  String get backupReminderMessage =>
      'Gỡ app hoặc đổi máy mà không có bản sao lưu sẽ mất các kênh vĩnh viễn.';

  @override
  String get backupReminderAction => 'Sao lưu ngay';

  @override
  String get backupReminderLater => 'Để sau';

  @override
  String get vaultFallbackWarning =>
      'Kho khóa an toàn của máy đang lỗi nên một số dữ liệu nhạy cảm tạm lưu không mã hoá. Hãy khởi động lại máy; nếu vẫn báo lỗi, cập nhật hệ điều hành.';

  @override
  String get sessionRecoveryFailed =>
      'Phiên của thiết bị đã hết hạn và chưa đăng ký lại được. Kiểm tra kết nối rồi mở lại ứng dụng.';

  @override
  String get notifyOwnRelayedTitle => 'Thông báo cả tin máy này chuyển tiếp';

  @override
  String get notifyOwnRelayedSubtitle =>
      'Mặc định tắt: máy chủ kênh đã có SMS gốc nên không cần thông báo trùng.';

  @override
  String smsOfflineCached(String time) {
    return 'Ngoại tuyến — đang xem bản lưu lúc $time';
  }

  @override
  String get splashMaintenanceDefault =>
      'Hệ thống đang bảo trì. Vui lòng thử lại sau ít phút.';

  @override
  String get whitelistPillAllSenders => 'Mọi người gửi';

  @override
  String whitelistPillOverflow(int count) {
    return '+$count';
  }

  @override
  String get whitelistPillOtpAllowed => 'Được gửi OTP';

  @override
  String get whitelistNoSenders => 'Chưa có người gửi nào trong bộ lọc';

  @override
  String get deviceTabTitle => 'Thiết bị';

  @override
  String get relayStatusSuccess => 'Đã chuyển tiếp';

  @override
  String get relayStatusEnqueued => 'Đang gửi';

  @override
  String get relayStatusRetrying => 'Đang thử lại';

  @override
  String get relayStatusParked => 'Chờ mở app';

  @override
  String get relayStatusFailed => 'Lỗi';

  @override
  String get relayStatusBlocked => 'Bị lọc';

  @override
  String get relayStatusSkipped => 'Bỏ qua';

  @override
  String get relayStatusUnknown => 'Không rõ';

  @override
  String get activityTabTitle => 'Hoạt động';

  @override
  String get activityFilterAll => 'Tất cả';

  @override
  String get activityFilterRelay => 'SMS chuyển tiếp';

  @override
  String get activityFilterChannels => 'Kênh';

  @override
  String get activityEmptyTitle => 'Chưa có hoạt động';

  @override
  String get activityEmptyMessage =>
      'SMS máy này chuyển tiếp và các sự kiện của kênh (yêu cầu tham gia, duyệt, rời kênh…) sẽ hiện ở đây.';

  @override
  String get activityUnknownChannel => '(không rõ tên)';

  @override
  String activityJoinRequest(String device, String channel) {
    return '$device xin tham gia kênh \"$channel\"';
  }

  @override
  String activityJoinRequestAnonymous(String channel) {
    return 'Có yêu cầu tham gia kênh \"$channel\"';
  }

  @override
  String activityApproved(String channel) {
    return 'Bạn đã được duyệt vào kênh \"$channel\"';
  }

  @override
  String activityRevoked(String channel) {
    return 'Bạn đã bị thu hồi quyền ở kênh \"$channel\"';
  }

  @override
  String activityArchived(String channel) {
    return 'Kênh \"$channel\" đã bị giải tán';
  }

  @override
  String activityMemberLeft(String device, String channel) {
    return '$device đã rời kênh \"$channel\"';
  }

  @override
  String activityMemberLeftAnonymous(String channel) {
    return 'Một thành viên đã rời kênh \"$channel\"';
  }
}
