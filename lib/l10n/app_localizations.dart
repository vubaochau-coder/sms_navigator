import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('vi')];

  /// No description provided for @appTitle.
  ///
  /// In vi, this message translates to:
  /// **'OTP Relay'**
  String get appTitle;

  /// No description provided for @roleSelectionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chọn Chế Độ Hoạt Động'**
  String get roleSelectionTitle;

  /// No description provided for @roleSelectionSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Ghép đôi và tự động chuyển tiếp OTP giữa Việt Nam và Malaysia'**
  String get roleSelectionSubtitle;

  /// No description provided for @roleSenderTitle.
  ///
  /// In vi, this message translates to:
  /// **'Máy Gửi (Việt Nam)'**
  String get roleSenderTitle;

  /// No description provided for @roleSenderDesc.
  ///
  /// In vi, this message translates to:
  /// **'Điện thoại cắm SIM Viettel nhận SMS OTP và tự động chuyển tiếp ngầm.'**
  String get roleSenderDesc;

  /// No description provided for @roleReceiverTitle.
  ///
  /// In vi, this message translates to:
  /// **'Máy Nhận (Malaysia)'**
  String get roleReceiverTitle;

  /// No description provided for @roleReceiverDesc.
  ///
  /// In vi, this message translates to:
  /// **'Nhận mã OTP qua Internet và hiển thị thông báo tức thì kèm nút sao chép.'**
  String get roleReceiverDesc;

  /// No description provided for @pairingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ghép Đôi Thiết Bị'**
  String get pairingTitle;

  /// No description provided for @pairingSenderGuide.
  ///
  /// In vi, this message translates to:
  /// **'Hiển thị mã QR để thiết bị Máy Nhận quét và thiết lập kênh E2EE.'**
  String get pairingSenderGuide;

  /// No description provided for @pairingReceiverGuide.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã QR trên Máy Gửi để thiết lập kênh mã hóa E2EE.'**
  String get pairingReceiverGuide;

  /// No description provided for @senderDashboardTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bảng Điều Khiển Máy Gửi'**
  String get senderDashboardTitle;

  /// No description provided for @receiverDashboardTitle.
  ///
  /// In vi, this message translates to:
  /// **'Danh Sách OTP Nhận Được'**
  String get receiverDashboardTitle;

  /// No description provided for @statusOnline.
  ///
  /// In vi, this message translates to:
  /// **'Đang hoạt động'**
  String get statusOnline;

  /// No description provided for @statusOffline.
  ///
  /// In vi, this message translates to:
  /// **'Đang tạm dừng'**
  String get statusOffline;

  /// No description provided for @statusWaitingPair.
  ///
  /// In vi, this message translates to:
  /// **'Chưa ghép đôi'**
  String get statusWaitingPair;

  /// No description provided for @batteryOptimizationTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tối ưu hóa Pin'**
  String get batteryOptimizationTitle;

  /// No description provided for @batteryOptimizationDesc.
  ///
  /// In vi, this message translates to:
  /// **'Cho phép app chạy ngầm không bị hệ điều hành tắt để nhận SMS.'**
  String get batteryOptimizationDesc;

  /// No description provided for @confirm.
  ///
  /// In vi, this message translates to:
  /// **'Xác nhận'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In vi, this message translates to:
  /// **'Hủy bỏ'**
  String get cancel;

  /// No description provided for @close.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get close;

  /// No description provided for @copy.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép'**
  String get copy;

  /// No description provided for @copiedToClipboard.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép vào bộ nhớ tạm'**
  String get copiedToClipboard;

  /// No description provided for @copiedWithLabel.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép {label}: {value}'**
  String copiedWithLabel(String label, String value);

  /// No description provided for @success.
  ///
  /// In vi, this message translates to:
  /// **'Thành công'**
  String get success;

  /// No description provided for @error.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi'**
  String get error;

  /// No description provided for @warning.
  ///
  /// In vi, this message translates to:
  /// **'Cảnh báo'**
  String get warning;

  /// No description provided for @info.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin'**
  String get info;

  /// No description provided for @pairingGenerateQr.
  ///
  /// In vi, this message translates to:
  /// **'Tạo mã QR ghép đôi'**
  String get pairingGenerateQr;

  /// No description provided for @pairingScanQr.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã QR'**
  String get pairingScanQr;

  /// No description provided for @pairingSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Ghép đôi thiết bị thành công!'**
  String get pairingSuccess;

  /// No description provided for @pairingFailed.
  ///
  /// In vi, this message translates to:
  /// **'Ghép đôi thất bại. Vui lòng thử lại!'**
  String get pairingFailed;

  /// No description provided for @pairingQrExpired.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR không hợp lệ hoặc đã hết hạn.'**
  String get pairingQrExpired;

  /// No description provided for @disconnect.
  ///
  /// In vi, this message translates to:
  /// **'Ngắt kết nối'**
  String get disconnect;

  /// No description provided for @disconnectSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy kết nối thành công'**
  String get disconnectSuccess;

  /// No description provided for @disconnectFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể hủy kết nối'**
  String get disconnectFailed;

  /// No description provided for @confirmRevokeSenderTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hủy kết nối máy gửi?'**
  String get confirmRevokeSenderTitle;

  /// No description provided for @confirmRevokeSenderMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn ngắt kết nối với \"{name}\"? Bạn sẽ không nhận được OTP từ thiết bị này nữa.'**
  String confirmRevokeSenderMessage(String name);

  /// No description provided for @confirmRevokeReceiverTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hủy kết nối thiết bị?'**
  String get confirmRevokeReceiverTitle;

  /// No description provided for @confirmRevokeReceiverMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn có chắc chắn muốn ngắt kết nối với \"{name}\"? Thiết bị này sẽ không thể nhận OTP từ bạn nữa.'**
  String confirmRevokeReceiverMessage(String name);

  /// No description provided for @relayEnabled.
  ///
  /// In vi, this message translates to:
  /// **'Đã kích hoạt dịch vụ chuyển tiếp'**
  String get relayEnabled;

  /// No description provided for @relayDisabled.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạm dừng dịch vụ chuyển tiếp'**
  String get relayDisabled;

  /// No description provided for @relayModeOtpOnly.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ chuyển tiếp mã OTP'**
  String get relayModeOtpOnly;

  /// No description provided for @relayModeAllSms.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển tiếp tất cả SMS'**
  String get relayModeAllSms;

  /// No description provided for @relayModeChanged.
  ///
  /// In vi, this message translates to:
  /// **'Đã chuyển sang chế độ: {mode}'**
  String relayModeChanged(String mode);

  /// No description provided for @addWhitelistSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã thêm địa chỉ {address} vào bộ lọc'**
  String addWhitelistSuccess(String address);

  /// No description provided for @removeWhitelistSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa địa chỉ {address}'**
  String removeWhitelistSuccess(String address);

  /// No description provided for @addWhitelistHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập đầu số hoặc brandname gửi tin (VD: VCB, BIDV, 1555). Địa chỉ được so khớp chính xác toàn phần, phân biệt hoa thường.'**
  String get addWhitelistHint;

  /// No description provided for @otpListTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử nhận OTP'**
  String get otpListTitle;

  /// No description provided for @otpListEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có mã OTP nào được ghi nhận'**
  String get otpListEmpty;

  /// No description provided for @otpDetailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết tin nhắn OTP'**
  String get otpDetailTitle;

  /// No description provided for @otpCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép mã OTP'**
  String get otpCopied;

  /// No description provided for @filterByDate.
  ///
  /// In vi, this message translates to:
  /// **'Lọc theo ngày'**
  String get filterByDate;

  /// No description provided for @groupByDevice.
  ///
  /// In vi, this message translates to:
  /// **'Gom nhóm theo thiết bị'**
  String get groupByDevice;

  /// No description provided for @senderDevice.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị gửi'**
  String get senderDevice;

  /// No description provided for @receivedAt.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian nhận'**
  String get receivedAt;

  /// No description provided for @content.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung'**
  String get content;

  /// No description provided for @serverSettingsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Cấu hình Server Backend'**
  String get serverSettingsTitle;

  /// No description provided for @serverSettingsSaved.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu cấu hình server: {url}'**
  String serverSettingsSaved(String url);

  /// No description provided for @serverSettingsFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể lưu cấu hình. Thử lại sau.'**
  String get serverSettingsFailed;

  /// No description provided for @navTabSms.
  ///
  /// In vi, this message translates to:
  /// **'SMS'**
  String get navTabSms;

  /// No description provided for @navTabPairing.
  ///
  /// In vi, this message translates to:
  /// **'Ghép nối'**
  String get navTabPairing;

  /// No description provided for @pairingHubTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ghép Nối Thiết Bị'**
  String get pairingHubTitle;

  /// No description provided for @pairingHubTabReceivers.
  ///
  /// In vi, this message translates to:
  /// **'Máy nhận'**
  String get pairingHubTabReceivers;

  /// No description provided for @pairingHubTabSenders.
  ///
  /// In vi, this message translates to:
  /// **'Máy gửi'**
  String get pairingHubTabSenders;

  /// No description provided for @pairingHubReceiversDesc.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách các máy đang nhận SMS của bạn'**
  String get pairingHubReceiversDesc;

  /// No description provided for @pairingHubSendersDesc.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách các máy gửi SMS cho bạn'**
  String get pairingHubSendersDesc;

  /// No description provided for @pairingHubCreateQr.
  ///
  /// In vi, this message translates to:
  /// **'Tạo mã QR'**
  String get pairingHubCreateQr;

  /// No description provided for @pairingHubScanQr.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã'**
  String get pairingHubScanQr;

  /// No description provided for @pairingHubAddNew.
  ///
  /// In vi, this message translates to:
  /// **'Thêm thiết bị ghép nối'**
  String get pairingHubAddNew;

  /// No description provided for @pairingHubAddReceiver.
  ///
  /// In vi, this message translates to:
  /// **'Thêm máy nhận (Tạo mã QR)'**
  String get pairingHubAddReceiver;

  /// No description provided for @pairingHubAddSender.
  ///
  /// In vi, this message translates to:
  /// **'Thêm máy gửi (Quét mã QR)'**
  String get pairingHubAddSender;

  /// No description provided for @settingsAction.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settingsAction;

  /// No description provided for @otpTodayWithDate.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay, {date}'**
  String otpTodayWithDate(String date);

  /// No description provided for @themeSwitchToLight.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển sang nền sáng'**
  String get themeSwitchToLight;

  /// No description provided for @themeSwitchToDark.
  ///
  /// In vi, this message translates to:
  /// **'Chuyển sang nền tối'**
  String get themeSwitchToDark;

  /// No description provided for @otpCopiedMessage.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép mã OTP: {otp}'**
  String otpCopiedMessage(String otp);

  /// No description provided for @otpSmsNotification.
  ///
  /// In vi, this message translates to:
  /// **'THÔNG BÁO SMS'**
  String get otpSmsNotification;

  /// No description provided for @otpCopyAction.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép mã'**
  String get otpCopyAction;

  /// No description provided for @otpViewFullMessage.
  ///
  /// In vi, this message translates to:
  /// **'Xem toàn bộ tin nhắn'**
  String get otpViewFullMessage;

  /// No description provided for @otpEmptyInDate.
  ///
  /// In vi, this message translates to:
  /// **'Không có mã OTP nào trong ngày {date}'**
  String otpEmptyInDate(String date);

  /// No description provided for @otpEmptyGuide.
  ///
  /// In vi, this message translates to:
  /// **'Các tin nhắn OTP hoặc SMS được relay trong ngày này sẽ xuất hiện tại đây. Bạn có thể chọn ngày khác trên thanh lịch phía trên.'**
  String get otpEmptyGuide;

  /// No description provided for @otpFilterDateWithCount.
  ///
  /// In vi, this message translates to:
  /// **'Ngày: {date} ({count} tin)'**
  String otpFilterDateWithCount(String date, int count);

  /// No description provided for @otpGroupByDevice.
  ///
  /// In vi, this message translates to:
  /// **'Nhóm theo máy'**
  String get otpGroupByDevice;

  /// No description provided for @smsFilterAll.
  ///
  /// In vi, this message translates to:
  /// **'Tất cả'**
  String get smsFilterAll;

  /// No description provided for @smsFilterSent.
  ///
  /// In vi, this message translates to:
  /// **'SMS Gửi Đi'**
  String get smsFilterSent;

  /// No description provided for @smsFilterReceived.
  ///
  /// In vi, this message translates to:
  /// **'SMS Nhận Được'**
  String get smsFilterReceived;

  /// No description provided for @retry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In vi, this message translates to:
  /// **'Làm mới'**
  String get refresh;

  /// No description provided for @done.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất'**
  String get done;

  /// No description provided for @errorOccurred.
  ///
  /// In vi, this message translates to:
  /// **'Có lỗi xảy ra'**
  String get errorOccurred;

  /// No description provided for @emptySendersTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa kết nối máy gửi nào'**
  String get emptySendersTitle;

  /// No description provided for @emptySendersMessage.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị này chưa nhận OTP từ máy gửi nào. Vui lòng quét mã QR từ máy gửi để hoàn tất ghép đôi.'**
  String get emptySendersMessage;

  /// No description provided for @scanSenderQrAction.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã QR ghép đôi'**
  String get scanSenderQrAction;

  /// No description provided for @emptyReceiversTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có thiết bị nhận nào'**
  String get emptyReceiversTitle;

  /// No description provided for @emptyReceiversMessage.
  ///
  /// In vi, this message translates to:
  /// **'Hiện tại chưa có máy nhận nào ghép đôi với thiết bị này. Bấm nút bên dưới để tạo mã QR kết nối.'**
  String get emptyReceiversMessage;

  /// No description provided for @statusSending.
  ///
  /// In vi, this message translates to:
  /// **'Đang gửi'**
  String get statusSending;

  /// No description provided for @statusPaused.
  ///
  /// In vi, this message translates to:
  /// **'Đã tạm dừng'**
  String get statusPaused;

  /// No description provided for @statusSenderMaintaining.
  ///
  /// In vi, this message translates to:
  /// **'Đang duy trì gửi'**
  String get statusSenderMaintaining;

  /// No description provided for @statusSenderPaused.
  ///
  /// In vi, this message translates to:
  /// **'Người gửi tạm dừng'**
  String get statusSenderPaused;

  /// No description provided for @pairedAt.
  ///
  /// In vi, this message translates to:
  /// **'Ghép đôi lúc'**
  String get pairedAt;

  /// No description provided for @lastActiveAt.
  ///
  /// In vi, this message translates to:
  /// **'Hoạt động gần nhất'**
  String get lastActiveAt;

  /// No description provided for @lastReceivedAt.
  ///
  /// In vi, this message translates to:
  /// **'Lần nhận gần nhất'**
  String get lastReceivedAt;

  /// No description provided for @allowSendingOtp.
  ///
  /// In vi, this message translates to:
  /// **'Cho phép gửi OTP'**
  String get allowSendingOtp;

  /// No description provided for @pauseSendingOtp.
  ///
  /// In vi, this message translates to:
  /// **'Tạm dừng gửi OTP'**
  String get pauseSendingOtp;

  /// No description provided for @senderMaintainingDesc.
  ///
  /// In vi, this message translates to:
  /// **'Người gửi đang duy trì truyền tin. (Chỉ xem)'**
  String get senderMaintainingDesc;

  /// No description provided for @senderPausedDesc.
  ///
  /// In vi, this message translates to:
  /// **'Người gửi đang tạm dừng truyền tin. (Chỉ xem)'**
  String get senderPausedDesc;

  /// No description provided for @revokePairTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Hủy ghép đôi'**
  String get revokePairTooltip;

  /// No description provided for @qrPairingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR Ghép Đôi'**
  String get qrPairingTitle;

  /// No description provided for @qrPairingDesc.
  ///
  /// In vi, this message translates to:
  /// **'Dùng Thiết Bị Nhận để quét mã QR bên dưới, thiết lập kênh E2EE an toàn tức thì.'**
  String get qrPairingDesc;

  /// No description provided for @cannotGeneratePairingCode.
  ///
  /// In vi, this message translates to:
  /// **'Không thể tạo mã ghép đôi.'**
  String get cannotGeneratePairingCode;

  /// No description provided for @smsPermissionBannerWarning.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cấp quyền đọc SMS — tính năng chuyển tiếp OTP đang tạm dừng.'**
  String get smsPermissionBannerWarning;

  /// No description provided for @openAppSettingsAction.
  ///
  /// In vi, this message translates to:
  /// **'Mở Cài Đặt'**
  String get openAppSettingsAction;

  /// No description provided for @grantPermissionAction.
  ///
  /// In vi, this message translates to:
  /// **'Cấp Quyền'**
  String get grantPermissionAction;

  /// No description provided for @scannerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quét Mã Ghép Đôi'**
  String get scannerTitle;

  /// No description provided for @scannerAlignGuide.
  ///
  /// In vi, this message translates to:
  /// **'Căn chỉnh mã QR từ Máy Gửi vào giữa khung hình để hoàn tất ghép đôi'**
  String get scannerAlignGuide;

  /// No description provided for @deviceSetupTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thiết Lập Thiết Bị'**
  String get deviceSetupTitle;

  /// No description provided for @deviceSetupGuide.
  ///
  /// In vi, this message translates to:
  /// **'Hoàn tất các bước dưới đây để máy luôn bắt được SMS OTP và chuyển tiếp ổn định, kể cả khi ứng dụng bị đóng.'**
  String get deviceSetupGuide;

  /// No description provided for @stepSmsPermissionTitle.
  ///
  /// In vi, this message translates to:
  /// **'1. Quyền đọc tin nhắn SMS'**
  String get stepSmsPermissionTitle;

  /// No description provided for @stepRequiredForSender.
  ///
  /// In vi, this message translates to:
  /// **'(Bắt buộc với thiết bị gửi)'**
  String get stepRequiredForSender;

  /// No description provided for @stepRequiredForReceiver.
  ///
  /// In vi, this message translates to:
  /// **'(Bắt buộc với thiết bị nhận)'**
  String get stepRequiredForReceiver;

  /// No description provided for @stepBatteryOptimizationTitle.
  ///
  /// In vi, this message translates to:
  /// **'2. Miễn trừ tối ưu pin'**
  String get stepBatteryOptimizationTitle;

  /// No description provided for @stepAutostartTitle.
  ///
  /// In vi, this message translates to:
  /// **'3. Tự khởi chạy (Autostart) — {oem}'**
  String stepAutostartTitle(String oem);

  /// No description provided for @stepBackgroundTitle.
  ///
  /// In vi, this message translates to:
  /// **'3. Cho phép chạy nền & tự khởi chạy'**
  String get stepBackgroundTitle;

  /// No description provided for @openAppDetailsAction.
  ///
  /// In vi, this message translates to:
  /// **'Mở Cài Đặt Ứng Dụng'**
  String get openAppDetailsAction;

  /// No description provided for @grantPermissionStepAction.
  ///
  /// In vi, this message translates to:
  /// **'Cấp Quyền'**
  String get grantPermissionStepAction;

  /// No description provided for @requestBatteryOptimizationAction.
  ///
  /// In vi, this message translates to:
  /// **'Yêu Cầu Miễn Trừ'**
  String get requestBatteryOptimizationAction;

  /// No description provided for @openAutostartAction.
  ///
  /// In vi, this message translates to:
  /// **'Mở Cài Đặt Autostart'**
  String get openAutostartAction;

  /// No description provided for @openBackgroundAction.
  ///
  /// In vi, this message translates to:
  /// **'Mở Cài Đặt Chạy Nền'**
  String get openBackgroundAction;

  /// No description provided for @reopenSettingsAction.
  ///
  /// In vi, this message translates to:
  /// **'Mở Lại Cài Đặt'**
  String get reopenSettingsAction;

  /// No description provided for @iHaveEnabledAction.
  ///
  /// In vi, this message translates to:
  /// **'Tôi Đã Bật'**
  String get iHaveEnabledAction;

  /// No description provided for @statusChecking.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra...'**
  String get statusChecking;

  /// No description provided for @statusCompleted.
  ///
  /// In vi, this message translates to:
  /// **'Đã hoàn tất'**
  String get statusCompleted;

  /// No description provided for @statusPendingConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ xác nhận'**
  String get statusPendingConfirm;

  /// No description provided for @statusNotDone.
  ///
  /// In vi, this message translates to:
  /// **'Chưa thực hiện'**
  String get statusNotDone;

  /// No description provided for @permissionDialogTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thiết lập quyền'**
  String get permissionDialogTitle;

  /// No description provided for @permissionDialogMessage.
  ///
  /// In vi, this message translates to:
  /// **'Một số quyền quan trọng chưa được cấp, ứng dụng có thể sẽ không hoạt động chính xác.'**
  String get permissionDialogMessage;

  /// No description provided for @dontRemindAgain.
  ///
  /// In vi, this message translates to:
  /// **'Không nhắc lại'**
  String get dontRemindAgain;

  /// No description provided for @goToSettings.
  ///
  /// In vi, this message translates to:
  /// **'Đi đến cài đặt'**
  String get goToSettings;

  /// No description provided for @otpOriginalMessageTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung tin nhắn gốc:'**
  String get otpOriginalMessageTitle;

  /// No description provided for @otpNoContent.
  ///
  /// In vi, this message translates to:
  /// **'[Không có nội dung]'**
  String get otpNoContent;

  /// No description provided for @otpCopyFullMessage.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép toàn bộ tin nhắn'**
  String get otpCopyFullMessage;

  /// No description provided for @otpCopiedFullMessage.
  ///
  /// In vi, this message translates to:
  /// **'toàn bộ tin nhắn'**
  String get otpCopiedFullMessage;

  /// No description provided for @otpAuthCodeTitle.
  ///
  /// In vi, this message translates to:
  /// **'MÃ XÁC THỰC (OTP)'**
  String get otpAuthCodeTitle;

  /// No description provided for @otpLabel.
  ///
  /// In vi, this message translates to:
  /// **'mã OTP'**
  String get otpLabel;

  /// No description provided for @smsRestrictedGuideTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nếu việc cấp quyền không thành công, thực hiện theo hướng dẫn sau:'**
  String get smsRestrictedGuideTitle;

  /// No description provided for @smsRestrictedGuideStep1Prefix.
  ///
  /// In vi, this message translates to:
  /// **'- Bấm vào '**
  String get smsRestrictedGuideStep1Prefix;

  /// No description provided for @smsRestrictedGuideStep1Action.
  ///
  /// In vi, this message translates to:
  /// **'\"Cài đặt ứng dụng\"'**
  String get smsRestrictedGuideStep1Action;

  /// No description provided for @smsRestrictedGuideStep1Suffix.
  ///
  /// In vi, this message translates to:
  /// **' (góc trên phải chọn 3 chấm ⋮ ➔ Cho phép cài đặt bị hạn chế).'**
  String get smsRestrictedGuideStep1Suffix;

  /// No description provided for @smsRestrictedGuideStep2Prefix.
  ///
  /// In vi, this message translates to:
  /// **'- Quay lại '**
  String get smsRestrictedGuideStep2Prefix;

  /// No description provided for @smsRestrictedGuideStep2Action.
  ///
  /// In vi, this message translates to:
  /// **'Quyền ứng dụng'**
  String get smsRestrictedGuideStep2Action;

  /// No description provided for @smsRestrictedGuideStep2Suffix.
  ///
  /// In vi, this message translates to:
  /// **' ➔ Bật quyền SMS (Tin nhắn).'**
  String get smsRestrictedGuideStep2Suffix;

  /// No description provided for @whitelistSettingsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc tin nhắn gửi'**
  String get whitelistSettingsTitle;

  /// No description provided for @whitelistAllAddressesToggle.
  ///
  /// In vi, this message translates to:
  /// **'Nhận từ mọi địa chỉ'**
  String get whitelistAllAddressesToggle;

  /// No description provided for @whitelistAllAddressesDesc.
  ///
  /// In vi, this message translates to:
  /// **'SMS thường từ mọi đầu số được chuyển tiếp. Riêng OTP bắt buộc phải liệt kê từng địa chỉ bên dưới.'**
  String get whitelistAllAddressesDesc;

  /// No description provided for @whitelistExplicitDesc.
  ///
  /// In vi, this message translates to:
  /// **'Chỉ SMS từ các địa chỉ trong danh sách được chuyển tiếp. Danh sách trống nghĩa là chặn tất cả.'**
  String get whitelistExplicitDesc;

  /// No description provided for @whitelistOtpSectionCaption.
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ được cấp quyền gửi OTP'**
  String get whitelistOtpSectionCaption;

  /// No description provided for @whitelistEmptyListHint.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có địa chỉ nào. Thêm đầu số hoặc brandname để bắt đầu.'**
  String get whitelistEmptyListHint;

  /// No description provided for @whitelistEmptyWarningTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cấu hình bộ lọc gửi'**
  String get whitelistEmptyWarningTitle;

  /// No description provided for @whitelistEmptyWarningMessage.
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn SMS đang tạm dừng chuyển tiếp để bảo vệ an toàn dữ liệu. Thêm địa chỉ bạn muốn chuyển tiếp.'**
  String get whitelistEmptyWarningMessage;

  /// No description provided for @whitelistConfigureAction.
  ///
  /// In vi, this message translates to:
  /// **'Cấu hình ngay'**
  String get whitelistConfigureAction;

  /// No description provided for @addWhitelistDialogTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thêm địa chỉ'**
  String get addWhitelistDialogTitle;

  /// No description provided for @whitelistDuplicateError.
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ \"{address}\" đã có trong danh sách'**
  String whitelistDuplicateError(String address);

  /// No description provided for @whitelistEmptyAddressError.
  ///
  /// In vi, this message translates to:
  /// **'Địa chỉ không được để trống'**
  String get whitelistEmptyAddressError;

  /// No description provided for @whitelistLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể đọc cấu hình bộ lọc'**
  String get whitelistLoadFailed;

  /// No description provided for @whitelistSaveFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể lưu cấu hình bộ lọc'**
  String get whitelistSaveFailed;

  /// No description provided for @whitelistRemoveAction.
  ///
  /// In vi, this message translates to:
  /// **'Xóa địa chỉ'**
  String get whitelistRemoveAction;

  /// No description provided for @saveQrImageAction.
  ///
  /// In vi, this message translates to:
  /// **'Lưu ảnh QR'**
  String get saveQrImageAction;

  /// No description provided for @qrImageExportSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu ảnh mã QR vào thư viện máy'**
  String get qrImageExportSuccess;

  /// No description provided for @qrImageExportFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể lưu ảnh mã QR. Vui lòng thử lại.'**
  String get qrImageExportFailed;

  /// No description provided for @qrImageExportPermissionDenied.
  ///
  /// In vi, this message translates to:
  /// **'Chưa được cấp quyền lưu ảnh vào thư viện'**
  String get qrImageExportPermissionDenied;

  /// No description provided for @qrImageExportNoQr.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có mã QR ghép đôi để lưu'**
  String get qrImageExportNoQr;

  /// No description provided for @scannerPickFromGallery.
  ///
  /// In vi, this message translates to:
  /// **'Chọn ảnh từ thư viện'**
  String get scannerPickFromGallery;

  /// No description provided for @scannerNoQrFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy mã QR trong ảnh đã chọn'**
  String get scannerNoQrFound;

  /// No description provided for @scannerUnsupportedQr.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR này không được SMS Navigator hỗ trợ'**
  String get scannerUnsupportedQr;

  /// No description provided for @pairingLinkedChip.
  ///
  /// In vi, this message translates to:
  /// **'Đã kết nối — Máy B đã quét mã'**
  String get pairingLinkedChip;

  /// No description provided for @deeplinkPairingTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ghép đôi từ mã QR'**
  String get deeplinkPairingTitle;

  /// No description provided for @deeplinkPairingInProgress.
  ///
  /// In vi, this message translates to:
  /// **'Đang ghép nối...'**
  String get deeplinkPairingInProgress;

  /// No description provided for @deeplinkPairingSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghép nối thành công'**
  String get deeplinkPairingSuccess;

  /// No description provided for @deeplinkPairingFailed.
  ///
  /// In vi, this message translates to:
  /// **'Ghép nối không thành công'**
  String get deeplinkPairingFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
