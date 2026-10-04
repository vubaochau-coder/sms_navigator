import 'package:equatable/equatable.dart';

import '../../../core/enums/splash_status.dart';

class SplashState extends Equatable {
  final SplashStatus status;
  final String? errorMessage;

  const SplashState({
    this.status = SplashStatus.initial,
    this.errorMessage,
  });

  bool get isLoading =>
      status != SplashStatus.ready && status != SplashStatus.failure;

  bool get isReady => status == SplashStatus.ready;

  bool get isFailure => status == SplashStatus.failure;

  SplashState copyWith({
    SplashStatus? status,
    String? errorMessage,
  }) {
    return SplashState(
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, errorMessage];
}
