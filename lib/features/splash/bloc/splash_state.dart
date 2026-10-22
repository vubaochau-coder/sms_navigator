import 'package:equatable/equatable.dart';

import '../../../core/enums/splash_status.dart';

/// Loại lỗi khởi động — quyết định icon/hướng dẫn, không đoán qua nội dung chuỗi.
enum SplashFailureKind { network, server, unknown }

class SplashState extends Equatable {
  final SplashStatus status;
  final String? errorMessage;
  final SplashFailureKind? failureKind;

  const SplashState({
    this.status = SplashStatus.initial,
    this.errorMessage,
    this.failureKind,
  });

  bool get isLoading =>
      status != SplashStatus.ready &&
      status != SplashStatus.failure &&
      status != SplashStatus.awaitingSetupChoice;

  bool get isAwaitingSetupChoice => status == SplashStatus.awaitingSetupChoice;

  bool get isReady => status == SplashStatus.ready;

  bool get isFailure => status == SplashStatus.failure;

  SplashState copyWith({
    SplashStatus? status,
    String? errorMessage,
    SplashFailureKind? failureKind,
    bool clearError = false,
  }) {
    return SplashState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      failureKind: clearError ? null : (failureKind ?? this.failureKind),
    );
  }

  @override
  List<Object?> get props => [status, errorMessage, failureKind];
}
