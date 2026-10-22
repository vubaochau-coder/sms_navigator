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
  /// **'SMS Navigator'**
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

  /// No description provided for @deviceProfileTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thông tin & Thiết lập thiết bị'**
  String get deviceProfileTitle;

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

  /// No description provided for @pairingQrNoSecretHint.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR không chứa mật khẩu — nếu ảnh bị lộ, kẻ khác vẫn không đọc được tin nhắn của bạn.'**
  String get pairingQrNoSecretHint;

  /// No description provided for @pairingDeletePhotoReminder.
  ///
  /// In vi, this message translates to:
  /// **'Đã ghép nối thành công. Nhớ xóa ảnh QR trong thư viện và cuộc trò chuyện đã gửi.'**
  String get pairingDeletePhotoReminder;

  /// No description provided for @splashSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Ghép đôi và đồng bộ SMS an toàn'**
  String get splashSubtitle;

  /// No description provided for @splashInitializingApp.
  ///
  /// In vi, this message translates to:
  /// **'Đang khởi tạo ứng dụng...'**
  String get splashInitializingApp;

  /// No description provided for @splashInitializingServices.
  ///
  /// In vi, this message translates to:
  /// **'Đang khởi tạo các dịch vụ...'**
  String get splashInitializingServices;

  /// No description provided for @splashCheckingIdentityKey.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra khóa định danh thiết bị...'**
  String get splashCheckingIdentityKey;

  /// No description provided for @splashAuthenticatingDevice.
  ///
  /// In vi, this message translates to:
  /// **'Đang xác thực thiết bị với máy chủ...'**
  String get splashAuthenticatingDevice;

  /// No description provided for @splashRegisteringDevice.
  ///
  /// In vi, this message translates to:
  /// **'Đang đăng ký thiết bị mới...'**
  String get splashRegisteringDevice;

  /// No description provided for @splashSyncingChannels.
  ///
  /// In vi, this message translates to:
  /// **'Đang đồng bộ dữ liệu kênh...'**
  String get splashSyncingChannels;

  /// No description provided for @splashReady.
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng!'**
  String get splashReady;

  /// No description provided for @splashConnectionError.
  ///
  /// In vi, this message translates to:
  /// **'Không thể kết nối hoặc xác thực thiết bị: {error}'**
  String splashConnectionError(String error);

  /// No description provided for @splashRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get splashRetry;

  /// No description provided for @splashSkipOffline.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua & Vào chế độ ngoại tuyến'**
  String get splashSkipOffline;

  /// No description provided for @splashDefaultDeviceName.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị của tôi'**
  String get splashDefaultDeviceName;

  /// No description provided for @smsPageTitle.
  ///
  /// In vi, this message translates to:
  /// **'SMS'**
  String get smsPageTitle;

  /// No description provided for @smsRefreshTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Làm mới'**
  String get smsRefreshTooltip;

  /// No description provided for @smsEmptyInDate.
  ///
  /// In vi, this message translates to:
  /// **'Ngày {date} chưa có tin nhắn SMS nào'**
  String smsEmptyInDate(String date);

  /// No description provided for @smsDailyMessageCount.
  ///
  /// In vi, this message translates to:
  /// **'Danh sách tin nhắn trong ngày ({count})'**
  String smsDailyMessageCount(int count);

  /// No description provided for @smsDecryptError.
  ///
  /// In vi, this message translates to:
  /// **'Không giải mã được tin này'**
  String get smsDecryptError;

  /// No description provided for @smsChannelPrefix.
  ///
  /// In vi, this message translates to:
  /// **'Kênh: {channelName} · {time}'**
  String smsChannelPrefix(String channelName, String time);

  /// No description provided for @smsCopyTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép'**
  String get smsCopyTooltip;

  /// No description provided for @smsCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép: {otp}'**
  String smsCopied(String otp);

  /// No description provided for @smsLoadError.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được tin nhắn SMS của ngày này. Kiểm tra kết nối và thử lại.'**
  String get smsLoadError;

  /// No description provided for @smsLoadErrorTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lỗi tải tin nhắn'**
  String get smsLoadErrorTitle;

  /// No description provided for @channelPageTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kênh'**
  String get channelPageTitle;

  /// No description provided for @channelRenameDeviceTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Đổi tên thiết bị'**
  String get channelRenameDeviceTooltip;

  /// No description provided for @channelEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa tham gia kênh nào.\nTạo kênh mới hoặc quét mã mời.'**
  String get channelEmptyMessage;

  /// No description provided for @channelOwnedEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa tạo kênh nào.\nNhấn nút \"Tạo kênh\" bên dưới.'**
  String get channelOwnedEmptyMessage;

  /// No description provided for @channelJoinedEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn chưa tham gia kênh nào.\nQuét mã QR mời để tham gia kênh.'**
  String get channelJoinedEmptyMessage;

  /// No description provided for @channelOwnedSectionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kênh của bạn'**
  String get channelOwnedSectionTitle;

  /// No description provided for @channelJoinedSectionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Kênh bạn tham gia'**
  String get channelJoinedSectionTitle;

  /// No description provided for @channelCreateAction.
  ///
  /// In vi, this message translates to:
  /// **'Tạo kênh'**
  String get channelCreateAction;

  /// No description provided for @channelCreateDialogTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo kênh mới'**
  String get channelCreateDialogTitle;

  /// No description provided for @channelNameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên kênh'**
  String get channelNameLabel;

  /// No description provided for @channelNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: Kênh nhà'**
  String get channelNameHint;

  /// No description provided for @channelCreateConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Tạo'**
  String get channelCreateConfirm;

  /// No description provided for @channelRenameDialogTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đổi tên thiết bị'**
  String get channelRenameDialogTitle;

  /// No description provided for @channelDeviceNameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên hiển thị'**
  String get channelDeviceNameLabel;

  /// No description provided for @channelDeviceNameHint.
  ///
  /// In vi, this message translates to:
  /// **'Ví dụ: Pixel 8 của Minh'**
  String get channelDeviceNameHint;

  /// No description provided for @channelSaveConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get channelSaveConfirm;

  /// No description provided for @channelOwnerSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'{count} thành viên · epoch {epoch}'**
  String channelOwnerSubtitle(int count, int epoch);

  /// No description provided for @channelMemberSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ: {ownerName} · {count} thành viên'**
  String channelMemberSubtitle(String ownerName, int count);

  /// No description provided for @joinPageTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia kênh'**
  String get joinPageTitle;

  /// No description provided for @joinInvalidInviteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mã mời không hợp lệ'**
  String get joinInvalidInviteTitle;

  /// No description provided for @joinInvalidInviteMessage.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR này không đúng định dạng. Hãy xin Owner một mã mời mới.'**
  String get joinInvalidInviteMessage;

  /// No description provided for @joinExpiredInviteTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mã mời đã hết hạn'**
  String get joinExpiredInviteTitle;

  /// No description provided for @joinExpiredInviteMessage.
  ///
  /// In vi, this message translates to:
  /// **'Mã mời chỉ có hiệu lực 10 phút. Hãy xin Owner một mã mời mới.'**
  String get joinExpiredInviteMessage;

  /// No description provided for @joinIdleEmptyMessage.
  ///
  /// In vi, this message translates to:
  /// **'Chưa gửi yêu cầu tham gia nào'**
  String get joinIdleEmptyMessage;

  /// No description provided for @joinReenterInviteAction.
  ///
  /// In vi, this message translates to:
  /// **'Nhập lại mã mời'**
  String get joinReenterInviteAction;

  /// No description provided for @joinChannelLabel.
  ///
  /// In vi, this message translates to:
  /// **'Kênh: {channelName}'**
  String joinChannelLabel(String channelName);

  /// No description provided for @joinOwnerLabel.
  ///
  /// In vi, this message translates to:
  /// **'Chủ kênh: {ownerName}'**
  String joinOwnerLabel(String ownerName);

  /// No description provided for @joinDeviceNameLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tên thiết bị của bạn'**
  String get joinDeviceNameLabel;

  /// No description provided for @joinDismissAction.
  ///
  /// In vi, this message translates to:
  /// **'Để sau'**
  String get joinDismissAction;

  /// No description provided for @joinSendRequestAction.
  ///
  /// In vi, this message translates to:
  /// **'Gửi yêu cầu kết nối'**
  String get joinSendRequestAction;

  /// No description provided for @joinWaitingApprovalTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ duyệt'**
  String get joinWaitingApprovalTitle;

  /// No description provided for @joinWaitingApprovalMessage.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu đã được gửi tới máy chủ.'**
  String get joinWaitingApprovalMessage;

  /// No description provided for @joinWaitingApprovalChannelMessage.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi yêu cầu tham gia \"{channelName}\". Chờ máy chủ (Owner) duyệt.'**
  String joinWaitingApprovalChannelMessage(String channelName);

  /// No description provided for @joinCancelRequestAction.
  ///
  /// In vi, this message translates to:
  /// **'Hủy yêu cầu'**
  String get joinCancelRequestAction;

  /// No description provided for @joinCancelConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hủy yêu cầu?'**
  String get joinCancelConfirmTitle;

  /// No description provided for @joinCancelConfirmMessage.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu tham gia kênh sẽ bị hủy. Owner sẽ không thấy yêu cầu này nữa.'**
  String get joinCancelConfirmMessage;

  /// No description provided for @joinContinueWaitingAction.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục chờ'**
  String get joinContinueWaitingAction;

  /// No description provided for @channelDetailTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết kênh'**
  String get channelDetailTitle;

  /// No description provided for @channelDetailInviteTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Mời thành viên'**
  String get channelDetailInviteTooltip;

  /// No description provided for @channelDetailOwnerServer.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ (Owner): {ownerName}'**
  String channelDetailOwnerServer(String ownerName);

  /// No description provided for @channelDetailMemberCount.
  ///
  /// In vi, this message translates to:
  /// **'{count} thành viên'**
  String channelDetailMemberCount(int count);

  /// No description provided for @channelDetailCurrentEpoch.
  ///
  /// In vi, this message translates to:
  /// **'Epoch hiện tại: {epoch}'**
  String channelDetailCurrentEpoch(int epoch);

  /// No description provided for @channelDetailPendingRequestsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu chờ duyệt ({count})'**
  String channelDetailPendingRequestsTitle(int count);

  /// No description provided for @channelDetailApproveTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Duyệt'**
  String get channelDetailApproveTooltip;

  /// No description provided for @channelDetailRejectTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get channelDetailRejectTooltip;

  /// No description provided for @channelDetailApproveDialogTitle.
  ///
  /// In vi, this message translates to:
  /// **'Duyệt thành viên?'**
  String get channelDetailApproveDialogTitle;

  /// No description provided for @channelDetailApproveDialogMessage.
  ///
  /// In vi, this message translates to:
  /// **'Duyệt \"{deviceName}\" sẽ tự động xoay khóa kênh và cấp khóa mới cho mọi thành viên.'**
  String channelDetailApproveDialogMessage(String deviceName);

  /// No description provided for @channelDetailApproveConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Duyệt'**
  String get channelDetailApproveConfirm;

  /// No description provided for @channelDetailRejectDialogTitle.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối yêu cầu?'**
  String get channelDetailRejectDialogTitle;

  /// No description provided for @channelDetailRejectDialogMessage.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối \"{deviceName}\"? Mã QR đã dùng cho yêu cầu này sẽ không còn hiệu lực.'**
  String channelDetailRejectDialogMessage(String deviceName);

  /// No description provided for @channelDetailRejectConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Từ chối'**
  String get channelDetailRejectConfirm;

  /// No description provided for @channelDetailMembersTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thành viên ({count})'**
  String channelDetailMembersTitle(int count);

  /// No description provided for @channelDetailMemberJoinedEpoch.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia epoch {epoch}'**
  String channelDetailMemberJoinedEpoch(int epoch);

  /// No description provided for @channelDetailMemberRevokedStatus.
  ///
  /// In vi, this message translates to:
  /// **'Đã thu hồi'**
  String get channelDetailMemberRevokedStatus;

  /// No description provided for @channelDetailMemberOwner.
  ///
  /// In vi, this message translates to:
  /// **'Owner'**
  String get channelDetailMemberOwner;

  /// No description provided for @channelDetailRevokeTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Thu hồi'**
  String get channelDetailRevokeTooltip;

  /// No description provided for @channelDetailRevokeDialogTitle.
  ///
  /// In vi, this message translates to:
  /// **'Thu hồi thành viên?'**
  String get channelDetailRevokeDialogTitle;

  /// No description provided for @channelDetailRevokeDialogMessage.
  ///
  /// In vi, this message translates to:
  /// **'Thu hồi \"{deviceName}\" là hành động vĩnh viễn. Khóa kênh sẽ được xoay ngay để member này không đọc được tin mới.'**
  String channelDetailRevokeDialogMessage(String deviceName);

  /// No description provided for @channelDetailRevokeConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Thu hồi'**
  String get channelDetailRevokeConfirm;

  /// No description provided for @channelDetailInviteSheetTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mời thành viên'**
  String get channelDetailInviteSheetTitle;

  /// No description provided for @channelDetailInviteQrExpiresIn.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR hết hạn sau: {time}'**
  String channelDetailInviteQrExpiresIn(String time);

  /// No description provided for @channelDetailInviteQrExpired.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR đã hết hạn. Hãy nhấn tạo lại mã bên dưới.'**
  String get channelDetailInviteQrExpired;

  /// No description provided for @channelDetailInviteCreatingQr.
  ///
  /// In vi, this message translates to:
  /// **'Đang tạo mã mời...'**
  String get channelDetailInviteCreatingQr;

  /// No description provided for @channelDetailInviteHint.
  ///
  /// In vi, this message translates to:
  /// **'• Người tham gia dùng ứng dụng quét mã QR này để gửi yêu cầu.\n• Mỗi mã QR chỉ có hiệu lực 1 lần trong vòng 10 phút.\n• Mã không chứa mật khẩu hay dữ liệu nhạy cảm.'**
  String get channelDetailInviteHint;

  /// No description provided for @channelDetailInviteRegenerate.
  ///
  /// In vi, this message translates to:
  /// **'Tạo lại mã'**
  String get channelDetailInviteRegenerate;

  /// No description provided for @channelDetailInviteCopySuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép liên kết mời'**
  String get channelDetailInviteCopySuccess;

  /// No description provided for @channelDetailInviteCopyLink.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép link'**
  String get channelDetailInviteCopyLink;

  /// No description provided for @channelDetailInviteSaveQr.
  ///
  /// In vi, this message translates to:
  /// **'Lưu mã QR'**
  String get channelDetailInviteSaveQr;

  /// No description provided for @channelDetailInviteSaveQrSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu mã QR vào thư viện ảnh'**
  String get channelDetailInviteSaveQrSuccess;

  /// No description provided for @channelDetailInviteSaveQrFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể lưu mã QR. Vui lòng thử lại sau.'**
  String get channelDetailInviteSaveQrFailed;

  /// No description provided for @channelDetailInviteSaveQrPermissionDenied.
  ///
  /// In vi, this message translates to:
  /// **'Ứng dụng cần quyền truy cập ảnh để lưu mã QR'**
  String get channelDetailInviteSaveQrPermissionDenied;

  /// No description provided for @channelDetailInviteCreateAction.
  ///
  /// In vi, this message translates to:
  /// **'Tạo mã mời QR'**
  String get channelDetailInviteCreateAction;

  /// No description provided for @channelPendingRequestsHeader.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu đang chờ duyệt ({count})'**
  String channelPendingRequestsHeader(int count);

  /// No description provided for @channelPendingBadge.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ duyệt'**
  String get channelPendingBadge;

  /// No description provided for @channelCancelRequestSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã hủy yêu cầu tham gia kênh'**
  String get channelCancelRequestSuccess;

  /// No description provided for @channelCancelRequestFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không hủy được yêu cầu. Thử lại sau.'**
  String get channelCancelRequestFailed;

  /// No description provided for @updateDialogTitle.
  ///
  /// In vi, this message translates to:
  /// **'Có phiên bản mới'**
  String get updateDialogTitle;

  /// No description provided for @updateNowButton.
  ///
  /// In vi, this message translates to:
  /// **'Cập nhật ngay'**
  String get updateNowButton;

  /// No description provided for @updateLaterButton.
  ///
  /// In vi, this message translates to:
  /// **'Để sau'**
  String get updateLaterButton;

  /// No description provided for @updateForceNotice.
  ///
  /// In vi, this message translates to:
  /// **'Bắt buộc cập nhật để tiếp tục sử dụng'**
  String get updateForceNotice;

  /// No description provided for @updateMissingUrlMessage.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có liên kết tải phiên bản mới'**
  String get updateMissingUrlMessage;

  /// No description provided for @updateInvalidUrlMessage.
  ///
  /// In vi, this message translates to:
  /// **'Liên kết tải không hợp lệ'**
  String get updateInvalidUrlMessage;

  /// No description provided for @updateLaunchErrorMessage.
  ///
  /// In vi, this message translates to:
  /// **'Không thể mở liên kết tải'**
  String get updateLaunchErrorMessage;

  /// No description provided for @networkRequestCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu mạng đã bị hủy bỏ.'**
  String get networkRequestCancelled;

  /// No description provided for @networkConnectTimeout.
  ///
  /// In vi, this message translates to:
  /// **'Kết nối tới máy chủ quá thời gian chờ ({seconds}s).'**
  String networkConnectTimeout(int seconds);

  /// No description provided for @networkTransferTimeout.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian truyền dữ liệu với máy chủ quá hạn ({seconds}s).'**
  String networkTransferTimeout(int seconds);

  /// No description provided for @networkUnauthorized.
  ///
  /// In vi, this message translates to:
  /// **'Phiên xác thực thiết bị không hợp lệ hoặc đã hết hạn (401).'**
  String get networkUnauthorized;

  /// No description provided for @networkServerError.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ trả về lỗi (HTTP {status}).'**
  String networkServerError(String status);

  /// No description provided for @networkUnreachable.
  ///
  /// In vi, this message translates to:
  /// **'Không thể kết nối tới máy chủ: {detail}'**
  String networkUnreachable(String detail);

  /// No description provided for @networkOffline.
  ///
  /// In vi, this message translates to:
  /// **'Không kết nối được máy chủ. Kiểm tra mạng và thử lại.'**
  String get networkOffline;

  /// No description provided for @notificationChannelDescription.
  ///
  /// In vi, this message translates to:
  /// **'Chuông báo có yêu cầu duyệt / tin nhắn SMS mới / thay đổi kênh'**
  String get notificationChannelDescription;

  /// No description provided for @notificationDefaultBody.
  ///
  /// In vi, this message translates to:
  /// **'Có sự kiện mới trong kênh. Mở app để xem.'**
  String get notificationDefaultBody;

  /// No description provided for @notificationJoinRequestTitle.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu tham gia kênh'**
  String get notificationJoinRequestTitle;

  /// No description provided for @notificationJoinRequestBody.
  ///
  /// In vi, this message translates to:
  /// **'{requesterName} muốn tham gia kênh \"{channelName}\".'**
  String notificationJoinRequestBody(String requesterName, String channelName);

  /// No description provided for @notificationJoinRequestBodyNoChannel.
  ///
  /// In vi, this message translates to:
  /// **'{requesterName} muốn tham gia kênh.'**
  String notificationJoinRequestBodyNoChannel(String requesterName);

  /// No description provided for @notificationJoinRequestBodyGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Có thiết bị mới xin tham gia. Mở app để duyệt.'**
  String get notificationJoinRequestBodyGeneric;

  /// No description provided for @notificationApprovedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Yêu cầu đã được duyệt'**
  String get notificationApprovedTitle;

  /// No description provided for @notificationApprovedBody.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã được thêm vào kênh \"{channelName}\". Mở app để xem tin nhắn SMS.'**
  String notificationApprovedBody(String channelName);

  /// No description provided for @notificationApprovedBodyGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã được thêm vào kênh. Mở app để bắt đầu nhận tin nhắn SMS.'**
  String get notificationApprovedBodyGeneric;

  /// No description provided for @notificationRevokedTitle.
  ///
  /// In vi, this message translates to:
  /// **'Quyền truy cập đã bị thu hồi'**
  String get notificationRevokedTitle;

  /// No description provided for @notificationRevokedBody.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không còn quyền truy cập kênh \"{channelName}\".'**
  String notificationRevokedBody(String channelName);

  /// No description provided for @notificationRevokedBodyGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Bạn không còn quyền truy cập một kênh.'**
  String get notificationRevokedBodyGeneric;

  /// No description provided for @notificationNewMessageTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tin nhắn SMS mới'**
  String get notificationNewMessageTitle;

  /// No description provided for @notificationNewMessageBody.
  ///
  /// In vi, this message translates to:
  /// **'Có tin nhắn SMS mới từ kênh \"{channelName}\". Chạm để xem.'**
  String notificationNewMessageBody(String channelName);

  /// No description provided for @notificationNewMessageBodyGeneric.
  ///
  /// In vi, this message translates to:
  /// **'Có tin nhắn SMS mới vừa được chia sẻ. Chạm để xem.'**
  String get notificationNewMessageBodyGeneric;

  /// No description provided for @notificationOtpTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mã OTP: {code}'**
  String notificationOtpTitle(String code);

  /// No description provided for @notificationCopyAction.
  ///
  /// In vi, this message translates to:
  /// **'Sao chép'**
  String get notificationCopyAction;

  /// No description provided for @relativeJustNow.
  ///
  /// In vi, this message translates to:
  /// **'Vừa xong'**
  String get relativeJustNow;

  /// No description provided for @relativeMinutesAgo.
  ///
  /// In vi, this message translates to:
  /// **'{count} phút trước'**
  String relativeMinutesAgo(int count);

  /// No description provided for @relativeHoursAgo.
  ///
  /// In vi, this message translates to:
  /// **'{count} giờ trước'**
  String relativeHoursAgo(int count);

  /// No description provided for @relativeYesterdayAt.
  ///
  /// In vi, this message translates to:
  /// **'Hôm qua {time}'**
  String relativeYesterdayAt(String time);

  /// No description provided for @relativeDaysAgo.
  ///
  /// In vi, this message translates to:
  /// **'{count} ngày trước'**
  String relativeDaysAgo(int count);

  /// No description provided for @qrUnsupportedFormat.
  ///
  /// In vi, this message translates to:
  /// **'Mã QR không được hỗ trợ. Hãy quét mã mời từ SMS Navigator.'**
  String get qrUnsupportedFormat;

  /// No description provided for @qrUpdateRequired.
  ///
  /// In vi, this message translates to:
  /// **'Mã này cần phiên bản SMS Navigator mới hơn. Hãy cập nhật ứng dụng.'**
  String get qrUpdateRequired;

  /// No description provided for @qrCheckFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể kiểm tra mã kết nối. Vui lòng thử lại sau.'**
  String get qrCheckFailed;

  /// No description provided for @qrNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy mã mời. Hãy kiểm tra lại hoặc xin Chủ kênh mã mới.'**
  String get qrNotFound;

  /// No description provided for @qrRateLimited.
  ///
  /// In vi, this message translates to:
  /// **'Bạn thử quá nhiều lần. Vui lòng đợi một lát rồi thử lại.'**
  String get qrRateLimited;

  /// No description provided for @qrEntryTitle.
  ///
  /// In vi, this message translates to:
  /// **'Mã kết nối'**
  String get qrEntryTitle;

  /// No description provided for @qrEntryChecking.
  ///
  /// In vi, this message translates to:
  /// **'Đang kiểm tra mã kết nối…'**
  String get qrEntryChecking;

  /// No description provided for @qrEntryCheckFailedShort.
  ///
  /// In vi, this message translates to:
  /// **'Không thể kiểm tra mã kết nối.'**
  String get qrEntryCheckFailedShort;

  /// No description provided for @joinErrorAlreadyPending.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã có yêu cầu tham gia kênh này đang chờ duyệt.'**
  String get joinErrorAlreadyPending;

  /// No description provided for @joinErrorAlreadyMember.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị của bạn đã là thành viên của kênh này.'**
  String get joinErrorAlreadyMember;

  /// No description provided for @joinErrorExpired.
  ///
  /// In vi, this message translates to:
  /// **'Mã mời đã hết hạn. Hãy xin Chủ kênh một mã mời mới.'**
  String get joinErrorExpired;

  /// No description provided for @joinErrorUsed.
  ///
  /// In vi, this message translates to:
  /// **'Mã mời đã được sử dụng. Hãy xin Chủ kênh một mã mời mới.'**
  String get joinErrorUsed;

  /// No description provided for @joinErrorChannelArchived.
  ///
  /// In vi, this message translates to:
  /// **'Kênh này đã bị lưu trữ, không thể tham gia.'**
  String get joinErrorChannelArchived;

  /// No description provided for @joinClaimFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không gửi được yêu cầu. Kiểm tra kết nối và thử lại.'**
  String get joinClaimFailed;

  /// No description provided for @joinClaimFailedRetry.
  ///
  /// In vi, this message translates to:
  /// **'Không gửi được yêu cầu. Vui lòng thử lại sau.'**
  String get joinClaimFailedRetry;

  /// No description provided for @joinChannelFallbackName.
  ///
  /// In vi, this message translates to:
  /// **'kênh'**
  String get joinChannelFallbackName;

  /// No description provided for @joinRequestSent.
  ///
  /// In vi, this message translates to:
  /// **'Đã gửi yêu cầu tham gia {channelName}'**
  String joinRequestSent(String channelName);

  /// No description provided for @joinLoadingChannelInfo.
  ///
  /// In vi, this message translates to:
  /// **'Đang tải thông tin kênh...'**
  String get joinLoadingChannelInfo;

  /// No description provided for @joinYourDeviceFallback.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị của bạn'**
  String get joinYourDeviceFallback;

  /// No description provided for @back.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get back;

  /// No description provided for @copiedLabel.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép {label}'**
  String copiedLabel(String label);

  /// No description provided for @statusPending.
  ///
  /// In vi, this message translates to:
  /// **'Đang chờ'**
  String get statusPending;

  /// No description provided for @channelLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được danh sách kênh. Kiểm tra kết nối và thử lại.'**
  String get channelLoadFailed;

  /// No description provided for @channelCreateFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tạo được kênh. Thử lại sau.'**
  String get channelCreateFailed;

  /// No description provided for @deviceRenameFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không đổi được tên thiết bị. Thử lại sau.'**
  String get deviceRenameFailed;

  /// No description provided for @channelDetailLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được chi tiết kênh. Kiểm tra kết nối và thử lại.'**
  String get channelDetailLoadFailed;

  /// No description provided for @channelDetailApproved.
  ///
  /// In vi, this message translates to:
  /// **'Đã duyệt {deviceName}.'**
  String channelDetailApproved(String deviceName);

  /// No description provided for @channelDetailApproveConflict.
  ///
  /// In vi, this message translates to:
  /// **'Không duyệt được: trạng thái kênh đã thay đổi. Danh sách đã được làm mới, thử lại.'**
  String get channelDetailApproveConflict;

  /// No description provided for @channelDetailRejected.
  ///
  /// In vi, this message translates to:
  /// **'Đã từ chối {deviceName}.'**
  String channelDetailRejected(String deviceName);

  /// No description provided for @channelDetailRejectFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không từ chối được: yêu cầu có thể đã được xử lý.'**
  String get channelDetailRejectFailed;

  /// No description provided for @channelDetailRevoked.
  ///
  /// In vi, this message translates to:
  /// **'Đã thu hồi thành viên và xoay khóa kênh.'**
  String get channelDetailRevoked;

  /// No description provided for @channelDetailRevokeConflict.
  ///
  /// In vi, this message translates to:
  /// **'Không thu hồi được: trạng thái kênh đã thay đổi. Thử lại.'**
  String get channelDetailRevokeConflict;

  /// No description provided for @channelInviteCreateFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tạo được mã mời. Thử lại sau.'**
  String get channelInviteCreateFailed;

  /// No description provided for @whitelistSectionTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc tin nhắn (White-list)'**
  String get whitelistSectionTitle;

  /// No description provided for @whitelistConfigureButton.
  ///
  /// In vi, this message translates to:
  /// **'Cấu hình'**
  String get whitelistConfigureButton;

  /// No description provided for @whitelistSectionOwnerDesc.
  ///
  /// In vi, this message translates to:
  /// **'Thiết lập danh sách số điện thoại/Brandname được phép chuyển tiếp tin nhắn SMS và OTP qua kênh này.'**
  String get whitelistSectionOwnerDesc;

  /// No description provided for @whitelistSectionMemberDesc.
  ///
  /// In vi, this message translates to:
  /// **'Kênh này được bảo vệ bởi bộ lọc của Chủ kênh. Tin nhắn SMS sẽ được chuyển tiếp theo cấu hình bảo mật đã duyệt.'**
  String get whitelistSectionMemberDesc;

  /// No description provided for @whitelistVersionLabel.
  ///
  /// In vi, this message translates to:
  /// **'Phiên bản bộ lọc: v{version}'**
  String whitelistVersionLabel(int version);

  /// No description provided for @whitelistFilterTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bộ lọc: {channelName}'**
  String whitelistFilterTitle(String channelName);

  /// No description provided for @whitelistMissingChannelKey.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy khóa bảo mật kênh để mã hóa'**
  String get whitelistMissingChannelKey;

  /// No description provided for @whitelistConflict.
  ///
  /// In vi, this message translates to:
  /// **'Cấu hình đã thay đổi trên thiết bị khác. Vui lòng tải lại.'**
  String get whitelistConflict;

  /// No description provided for @whitelistSaveRequiresNetwork.
  ///
  /// In vi, this message translates to:
  /// **'Không thể lưu cấu hình (bắt buộc kết nối mạng): {detail}'**
  String whitelistSaveRequiresNetwork(String detail);

  /// No description provided for @whitelistSaveOffline.
  ///
  /// In vi, this message translates to:
  /// **'Không có kết nối mạng. Không thể lưu cấu hình bộ lọc.'**
  String get whitelistSaveOffline;

  /// No description provided for @relayLogTitle.
  ///
  /// In vi, this message translates to:
  /// **'Nhật ký tiếp nhận SMS'**
  String get relayLogTitle;

  /// No description provided for @relayLogDescription.
  ///
  /// In vi, this message translates to:
  /// **'Mỗi SMS tới sẽ được ghi lại tại đây kèm lý do bị chặn (nếu không relay được).'**
  String get relayLogDescription;

  /// No description provided for @relayLogEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có SMS nào được ghi nhận.'**
  String get relayLogEmpty;

  /// No description provided for @relayLogUnknownSender.
  ///
  /// In vi, this message translates to:
  /// **'(không rõ số gửi)'**
  String get relayLogUnknownSender;

  /// No description provided for @relayLogDetected.
  ///
  /// In vi, this message translates to:
  /// **'Nội dung phát hiện: {otp}'**
  String relayLogDetected(String otp);

  /// No description provided for @deviceRenameLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang cập nhật tên thiết bị...'**
  String get deviceRenameLoading;

  /// No description provided for @deviceRenameSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã cập nhật tên thiết bị'**
  String get deviceRenameSuccess;

  /// No description provided for @deviceResetLoading.
  ///
  /// In vi, this message translates to:
  /// **'Đang xóa dữ liệu thiết bị...'**
  String get deviceResetLoading;

  /// No description provided for @deviceResetSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã xóa dữ liệu thiết bị'**
  String get deviceResetSuccess;

  /// No description provided for @deviceResetFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể xóa dữ liệu thiết bị. Thử lại sau.'**
  String get deviceResetFailed;

  /// No description provided for @deviceResetDialogTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa dữ liệu thiết bị?'**
  String get deviceResetDialogTitle;

  /// No description provided for @deviceResetDialogMessage.
  ///
  /// In vi, this message translates to:
  /// **'Toàn bộ mã định danh, token xác thực và cấu hình trên thiết bị này sẽ bị xóa hoàn toàn khỏi máy.\n\nỨng dụng sẽ được khởi động lại từ đầu để bạn đăng ký mới.'**
  String get deviceResetDialogMessage;

  /// No description provided for @deviceResetConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Xóa dữ liệu'**
  String get deviceResetConfirm;

  /// No description provided for @deviceResetTitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa dữ liệu thiết bị'**
  String get deviceResetTitle;

  /// No description provided for @deviceResetSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Xóa mã định danh, token và khôi phục cài đặt gốc'**
  String get deviceResetSubtitle;

  /// No description provided for @devicePreferencesTitle.
  ///
  /// In vi, this message translates to:
  /// **'CÀI ĐẶT & TÙY CHỌN'**
  String get devicePreferencesTitle;

  /// No description provided for @themeModeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Chế độ hiển thị'**
  String get themeModeLabel;

  /// No description provided for @themeSystem.
  ///
  /// In vi, this message translates to:
  /// **'Hệ thống'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In vi, this message translates to:
  /// **'Sáng'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In vi, this message translates to:
  /// **'Tối'**
  String get themeDark;

  /// No description provided for @deviceSetupYourDevice.
  ///
  /// In vi, this message translates to:
  /// **'thiết bị của bạn'**
  String get deviceSetupYourDevice;

  /// No description provided for @deviceHealthTitle.
  ///
  /// In vi, this message translates to:
  /// **'TÌNH TRẠNG THIẾT BỊ'**
  String get deviceHealthTitle;

  /// No description provided for @deviceHealthReady.
  ///
  /// In vi, this message translates to:
  /// **'Sẵn sàng'**
  String get deviceHealthReady;

  /// No description provided for @deviceHealthNeedsAttention.
  ///
  /// In vi, this message translates to:
  /// **'Cần chú ý'**
  String get deviceHealthNeedsAttention;

  /// No description provided for @deviceHealthSmsPermission.
  ///
  /// In vi, this message translates to:
  /// **'Quyền đọc SMS'**
  String get deviceHealthSmsPermission;

  /// No description provided for @deviceHealthGranted.
  ///
  /// In vi, this message translates to:
  /// **'Đã cấp quyền'**
  String get deviceHealthGranted;

  /// No description provided for @deviceHealthNotGranted.
  ///
  /// In vi, this message translates to:
  /// **'Chưa cấp quyền'**
  String get deviceHealthNotGranted;

  /// No description provided for @deviceHealthGrantNow.
  ///
  /// In vi, this message translates to:
  /// **'Cấp ngay'**
  String get deviceHealthGrantNow;

  /// No description provided for @deviceHealthBackground.
  ///
  /// In vi, this message translates to:
  /// **'Chạy ngầm & Tối ưu pin'**
  String get deviceHealthBackground;

  /// No description provided for @deviceHealthBatteryUnrestricted.
  ///
  /// In vi, this message translates to:
  /// **'Đã tắt hạn chế pin'**
  String get deviceHealthBatteryUnrestricted;

  /// No description provided for @deviceHealthBatteryRestricted.
  ///
  /// In vi, this message translates to:
  /// **'Có thể bị hệ điều hành tắt'**
  String get deviceHealthBatteryRestricted;

  /// No description provided for @deviceHealthOemDetails.
  ///
  /// In vi, this message translates to:
  /// **'Chi tiết thiết lập thiết bị & cài đặt OEM'**
  String get deviceHealthOemDetails;

  /// No description provided for @deviceIdUnknown.
  ///
  /// In vi, this message translates to:
  /// **'Chưa xác định'**
  String get deviceIdUnknown;

  /// No description provided for @deviceIdCopied.
  ///
  /// In vi, this message translates to:
  /// **'Đã sao chép ID thiết bị'**
  String get deviceIdCopied;

  /// No description provided for @scanInviteTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Quét mã mời'**
  String get scanInviteTooltip;

  /// No description provided for @scannerPasteAction.
  ///
  /// In vi, this message translates to:
  /// **'Dán mã'**
  String get scannerPasteAction;

  /// No description provided for @scannerClipboardEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Bộ nhớ tạm không có mã nào để dán.'**
  String get scannerClipboardEmpty;

  /// No description provided for @scannerCameraPermissionRequired.
  ///
  /// In vi, this message translates to:
  /// **'Ứng dụng cần quyền truy cập máy ảnh để quét mã QR'**
  String get scannerCameraPermissionRequired;

  /// No description provided for @scannerCameraStartFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không thể khởi động máy ảnh: {detail}'**
  String scannerCameraStartFailed(String detail);

  /// No description provided for @splashServerError.
  ///
  /// In vi, this message translates to:
  /// **'Máy chủ đang gặp sự cố (HTTP {status}). Vui lòng thử lại sau.'**
  String splashServerError(String status);

  /// No description provided for @splashStartupFailed.
  ///
  /// In vi, this message translates to:
  /// **'Đã xảy ra sự cố trong quá trình khởi động hệ thống. Vui lòng thử lại.'**
  String get splashStartupFailed;

  /// No description provided for @backupSectionTitle.
  ///
  /// In vi, this message translates to:
  /// **'SAO LƯU & KHÔI PHỤC'**
  String get backupSectionTitle;

  /// No description provided for @backupExportTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo bản sao lưu'**
  String get backupExportTitle;

  /// No description provided for @backupExportSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Lưu danh tính và khoá kênh ra file .smsnav để cài lại app hoặc chuyển máy'**
  String get backupExportSubtitle;

  /// No description provided for @backupPassphraseTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đặt mật khẩu cho bản sao lưu'**
  String get backupPassphraseTitle;

  /// No description provided for @backupPassphraseMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bản sao lưu được mã hoá bằng mật khẩu này. Quên mật khẩu là không mở được file — hãy cất ở nơi an toàn.'**
  String get backupPassphraseMessage;

  /// No description provided for @backupExportWarning.
  ///
  /// In vi, this message translates to:
  /// **'File chứa khoá giải mã mọi tin nhắn của bạn. Đừng gửi file kèm mật khẩu cho người khác.'**
  String get backupExportWarning;

  /// No description provided for @backupPassphraseLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu'**
  String get backupPassphraseLabel;

  /// No description provided for @backupPassphraseConfirmLabel.
  ///
  /// In vi, this message translates to:
  /// **'Nhập lại mật khẩu'**
  String get backupPassphraseConfirmLabel;

  /// No description provided for @backupPassphraseTooShort.
  ///
  /// In vi, this message translates to:
  /// **'Tối thiểu {min} ký tự'**
  String backupPassphraseTooShort(int min);

  /// No description provided for @backupPassphraseMismatch.
  ///
  /// In vi, this message translates to:
  /// **'Mật khẩu nhập lại không khớp'**
  String get backupPassphraseMismatch;

  /// No description provided for @backupShowPassphrase.
  ///
  /// In vi, this message translates to:
  /// **'Hiện mật khẩu'**
  String get backupShowPassphrase;

  /// No description provided for @backupHidePassphrase.
  ///
  /// In vi, this message translates to:
  /// **'Ẩn mật khẩu'**
  String get backupHidePassphrase;

  /// No description provided for @backupExportConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Tạo & lưu file'**
  String get backupExportConfirm;

  /// No description provided for @backupExporting.
  ///
  /// In vi, this message translates to:
  /// **'Đang mã hoá bản sao lưu…'**
  String get backupExporting;

  /// No description provided for @backupExportSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã lưu {fileName}'**
  String backupExportSuccess(String fileName);

  /// No description provided for @backupRestoreTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục từ bản sao lưu'**
  String get backupRestoreTitle;

  /// No description provided for @backupRestoreIntro.
  ///
  /// In vi, this message translates to:
  /// **'Chọn file .smsnav đã tạo trên máy cũ rồi nhập mật khẩu. Máy này sẽ dùng lại đúng danh tính, các kênh và khoá cũ.'**
  String get backupRestoreIntro;

  /// No description provided for @backupRestoreOldDeviceWarning.
  ///
  /// In vi, this message translates to:
  /// **'Sau khi khôi phục, đừng dùng app trên máy cũ nữa — hai máy chung một danh tính sẽ tranh nhau nhận thông báo và relay SMS.'**
  String get backupRestoreOldDeviceWarning;

  /// No description provided for @backupPickFile.
  ///
  /// In vi, this message translates to:
  /// **'Chọn file sao lưu'**
  String get backupPickFile;

  /// No description provided for @backupFileSelected.
  ///
  /// In vi, this message translates to:
  /// **'Đã chọn file sao lưu'**
  String get backupFileSelected;

  /// No description provided for @backupChangeFile.
  ///
  /// In vi, this message translates to:
  /// **'Chọn file khác'**
  String get backupChangeFile;

  /// No description provided for @backupRestoreAction.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục'**
  String get backupRestoreAction;

  /// No description provided for @backupRestoring.
  ///
  /// In vi, this message translates to:
  /// **'Đang giải mã và khôi phục…'**
  String get backupRestoring;

  /// No description provided for @backupRestoreSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã khôi phục danh tính và khoá của {count} kênh'**
  String backupRestoreSuccess(int count);

  /// No description provided for @backupErrorWrongPassphrase.
  ///
  /// In vi, this message translates to:
  /// **'Sai mật khẩu, hoặc file đã bị chỉnh sửa.'**
  String get backupErrorWrongPassphrase;

  /// No description provided for @backupErrorInvalidFile.
  ///
  /// In vi, this message translates to:
  /// **'File này không phải bản sao lưu SMS Navigator hợp lệ.'**
  String get backupErrorInvalidFile;

  /// No description provided for @backupErrorUnsupportedVersion.
  ///
  /// In vi, this message translates to:
  /// **'Bản sao lưu được tạo bởi phiên bản app mới hơn. Hãy cập nhật app rồi thử lại.'**
  String get backupErrorUnsupportedVersion;

  /// No description provided for @backupErrorIncomplete.
  ///
  /// In vi, this message translates to:
  /// **'Bản sao lưu thiếu dữ liệu danh tính.'**
  String get backupErrorIncomplete;

  /// No description provided for @backupErrorNotRegistered.
  ///
  /// In vi, this message translates to:
  /// **'Thiết bị chưa đăng ký — chưa có gì để sao lưu.'**
  String get backupErrorNotRegistered;

  /// No description provided for @backupErrorStorage.
  ///
  /// In vi, this message translates to:
  /// **'Không đọc/ghi được file. Thử lại hoặc chọn vị trí khác.'**
  String get backupErrorStorage;

  /// No description provided for @splashSetupChoiceTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bạn muốn bắt đầu thế nào?'**
  String get splashSetupChoiceTitle;

  /// No description provided for @splashSetupNewDevice.
  ///
  /// In vi, this message translates to:
  /// **'Thiết lập thiết bị mới'**
  String get splashSetupNewDevice;

  /// No description provided for @splashSetupNewDeviceSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tạo danh tính mới cho máy này'**
  String get splashSetupNewDeviceSubtitle;

  /// No description provided for @splashSetupRestore.
  ///
  /// In vi, this message translates to:
  /// **'Khôi phục từ bản sao lưu'**
  String get splashSetupRestore;

  /// No description provided for @splashSetupRestoreSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Dùng file .smsnav từ máy cũ'**
  String get splashSetupRestoreSubtitle;

  /// No description provided for @channelDetailMoreTooltip.
  ///
  /// In vi, this message translates to:
  /// **'Tùy chọn kênh'**
  String get channelDetailMoreTooltip;

  /// No description provided for @channelRenameAction.
  ///
  /// In vi, this message translates to:
  /// **'Đổi tên kênh'**
  String get channelRenameAction;

  /// No description provided for @channelRenameConfirm.
  ///
  /// In vi, this message translates to:
  /// **'Lưu'**
  String get channelRenameConfirm;

  /// No description provided for @channelRenameSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã đổi tên kênh thành \"{channelName}\".'**
  String channelRenameSuccess(String channelName);

  /// No description provided for @channelRenameFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không đổi được tên kênh. Vui lòng thử lại.'**
  String get channelRenameFailed;

  /// No description provided for @channelLeaveAction.
  ///
  /// In vi, this message translates to:
  /// **'Rời kênh'**
  String get channelLeaveAction;

  /// No description provided for @channelLeaveConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Rời kênh này?'**
  String get channelLeaveConfirmTitle;

  /// No description provided for @channelLeaveConfirmMessage.
  ///
  /// In vi, this message translates to:
  /// **'Bạn sẽ không nhận và không xem được tin nhắn của \"{channelName}\" nữa. Muốn quay lại phải xin Chủ kênh mã mời mới.'**
  String channelLeaveConfirmMessage(String channelName);

  /// No description provided for @channelLeaveSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã rời kênh \"{channelName}\".'**
  String channelLeaveSuccess(String channelName);

  /// No description provided for @channelLeaveFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không rời được kênh. Vui lòng thử lại.'**
  String get channelLeaveFailed;

  /// No description provided for @channelArchiveAction.
  ///
  /// In vi, this message translates to:
  /// **'Giải tán kênh'**
  String get channelArchiveAction;

  /// No description provided for @channelArchiveConfirmTitle.
  ///
  /// In vi, this message translates to:
  /// **'Giải tán kênh?'**
  String get channelArchiveConfirmTitle;

  /// No description provided for @channelArchiveConfirmMessage.
  ///
  /// In vi, this message translates to:
  /// **'Kênh \"{channelName}\" sẽ bị xoá khỏi mọi thành viên, tin nhắn cũ không còn xem được và SMS sẽ ngừng chuyển tiếp. Không thể hoàn tác.'**
  String channelArchiveConfirmMessage(String channelName);

  /// No description provided for @channelArchiveSuccess.
  ///
  /// In vi, this message translates to:
  /// **'Đã giải tán kênh \"{channelName}\".'**
  String channelArchiveSuccess(String channelName);

  /// No description provided for @channelArchiveFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không giải tán được kênh. Vui lòng thử lại.'**
  String get channelArchiveFailed;

  /// No description provided for @requestHistoryAction.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử yêu cầu'**
  String get requestHistoryAction;

  /// No description provided for @requestHistoryTitle.
  ///
  /// In vi, this message translates to:
  /// **'Lịch sử yêu cầu kết nối'**
  String get requestHistoryTitle;

  /// No description provided for @requestHistoryEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có yêu cầu nào được xử lý.'**
  String get requestHistoryEmpty;

  /// No description provided for @requestHistoryLoadMore.
  ///
  /// In vi, this message translates to:
  /// **'Xem thêm'**
  String get requestHistoryLoadMore;

  /// No description provided for @requestHistoryLoadFailed.
  ///
  /// In vi, this message translates to:
  /// **'Không tải được lịch sử yêu cầu.'**
  String get requestHistoryLoadFailed;

  /// No description provided for @requestHistoryRetry.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại'**
  String get requestHistoryRetry;

  /// No description provided for @requestStatusApproved.
  ///
  /// In vi, this message translates to:
  /// **'Đã duyệt'**
  String get requestStatusApproved;

  /// No description provided for @requestStatusRejected.
  ///
  /// In vi, this message translates to:
  /// **'Đã từ chối'**
  String get requestStatusRejected;

  /// No description provided for @requestStatusCancelled.
  ///
  /// In vi, this message translates to:
  /// **'Đã huỷ'**
  String get requestStatusCancelled;
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
