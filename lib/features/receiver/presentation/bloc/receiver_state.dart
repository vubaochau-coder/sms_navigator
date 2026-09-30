import 'package:equatable/equatable.dart';
import '../../data/models/received_otp_model.dart';

class ReceiverState extends Equatable {
  final bool isLoading;
  final List<ReceivedOtpModel> otps;
  final String? errorMessage;
  final String? recentlyCopiedOtp;
  final ReceivedOtpModel? latestPushedOtp;

  const ReceiverState({
    this.isLoading = false,
    this.otps = const [],
    this.errorMessage,
    this.recentlyCopiedOtp,
    this.latestPushedOtp,
  });

  ReceiverState copyWith({
    bool? isLoading,
    List<ReceivedOtpModel>? otps,
    String? errorMessage,
    String? recentlyCopiedOtp,
    ReceivedOtpModel? latestPushedOtp,
    bool clearLatestOtp = false,
  }) {
    return ReceiverState(
      isLoading: isLoading ?? this.isLoading,
      otps: otps ?? this.otps,
      errorMessage: errorMessage,
      recentlyCopiedOtp: recentlyCopiedOtp ?? this.recentlyCopiedOtp,
      latestPushedOtp: clearLatestOtp
          ? null
          : (latestPushedOtp ?? this.latestPushedOtp),
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    otps,
    errorMessage,
    recentlyCopiedOtp,
    latestPushedOtp,
  ];
}
