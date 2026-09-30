import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/services/fcm_notification_service.dart';
import '../widgets/notification_presets_selector.dart';
import 'notification_test_state.dart';

class NotificationTestCubit extends Cubit<NotificationTestState> {
  NotificationTestCubit() : super(const NotificationTestState());

  Future<void> loadStatus() async {
    final status = await Permission.notification.status;
    final token =
        await DependencyContainer.instance.deviceStorageService.getFcmToken();
    emit(state.copyWith(
      hasNotificationPermission: status.isGranted,
      fcmToken: token,
    ));
  }

  void randomizeOtp() {
    final randomOtp =
        (100000 + (DateTime.now().millisecondsSinceEpoch % 900000)).toString();
    emit(state.copyWith(
      otp: randomOtp,
      rawMessage:
          'GD $randomOtp tai ${state.sender} DIGIBANK luc 22:35. Khong chia se ma OTP.',
    ));
  }

  void selectBankPreset(String bankName) {
    emit(state.copyWith(
      sender: bankName,
      rawMessage:
          'GD ${state.otp} tai $bankName luc 22:30. Khong chia se ma OTP.',
    ));
  }

  void selectChinesePreset(ChinesePresetItem item) {
    emit(state.copyWith(
      sender: item.sender,
      otp: item.otp,
      rawMessage: item.message,
    ));
  }

  Future<void> requestPermission() async {
    final result = await Permission.notification.request();
    emit(state.copyWith(
      hasNotificationPermission: result.isGranted,
      toastMessage: result.isGranted
          ? 'Đã cấp quyền thông báo thành công!'
          : 'Chưa cấp quyền thông báo.',
      isErrorToast: !result.isGranted,
    ));
  }

  Future<void> triggerReceiverNotification() async {
    emit(state.copyWith(isLoading: true, clearToast: true));
    HapticFeedback.mediumImpact();

    await FcmNotificationService.showDemoReceiverOtpNotification(
      sender: state.sender,
      otp: state.otp,
      rawMessage: state.rawMessage,
    );

    emit(state.copyWith(
      isLoading: false,
      toastMessage: 'Đã bắn thông báo: [${state.sender}] Mã OTP: ${state.otp}',
      isErrorToast: false,
    ));
  }

  Future<void> triggerSenderNotification() async {
    emit(state.copyWith(isLoading: true, clearToast: true));
    HapticFeedback.mediumImpact();

    await FcmNotificationService.showDemoSenderSuccessNotification(
      sender: state.sender,
      otp: state.otp,
      targetDevice: state.targetDevice,
    );

    emit(state.copyWith(
      isLoading: false,
      toastMessage:
          'Đã bắn thông báo: Gửi thành công mã ${state.otp} sang máy nhận!',
      isErrorToast: false,
    ));
  }
}
