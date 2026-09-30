import 'package:equatable/equatable.dart';

class NotificationTestState extends Equatable {
  final String sender;
  final String otp;
  final String rawMessage;
  final String targetDevice;
  final String? fcmToken;
  final bool hasNotificationPermission;
  final bool isLoading;
  final String? toastMessage;
  final bool isErrorToast;

  const NotificationTestState({
    this.sender = 'Vietcombank',
    this.otp = '849201',
    this.rawMessage =
        'GD 849201 tai VCB DIGIBANK luc 22:30. Khong chia se ma OTP cho bat ky ai.',
    this.targetDevice = 'Samsung S24 (Malaysia)',
    this.fcmToken,
    this.hasNotificationPermission = true,
    this.isLoading = false,
    this.toastMessage,
    this.isErrorToast = false,
  });

  NotificationTestState copyWith({
    String? sender,
    String? otp,
    String? rawMessage,
    String? targetDevice,
    String? fcmToken,
    bool? hasNotificationPermission,
    bool? isLoading,
    String? toastMessage,
    bool? isErrorToast,
    bool clearToast = false,
  }) {
    return NotificationTestState(
      sender: sender ?? this.sender,
      otp: otp ?? this.otp,
      rawMessage: rawMessage ?? this.rawMessage,
      targetDevice: targetDevice ?? this.targetDevice,
      fcmToken: fcmToken ?? this.fcmToken,
      hasNotificationPermission:
          hasNotificationPermission ?? this.hasNotificationPermission,
      isLoading: isLoading ?? this.isLoading,
      toastMessage: clearToast ? null : (toastMessage ?? this.toastMessage),
      isErrorToast: isErrorToast ?? this.isErrorToast,
    );
  }

  @override
  List<Object?> get props => [
    sender,
    otp,
    rawMessage,
    targetDevice,
    fcmToken,
    hasNotificationPermission,
    isLoading,
    toastMessage,
    isErrorToast,
  ];
}
