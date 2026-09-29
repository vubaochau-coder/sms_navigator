import 'package:equatable/equatable.dart';
import '../../data/models/pairing_payload_model.dart';

class PairingState extends Equatable {
  static const int defaultCountdownSeconds = 600;

  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final PairingPayloadModel? pairingPayload;
  final bool isPaired;
  final int countdownSeconds;

  const PairingState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
    this.pairingPayload,
    this.isPaired = false,
    this.countdownSeconds = defaultCountdownSeconds,
  });

  PairingState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    PairingPayloadModel? pairingPayload,
    bool? isPaired,
    int? countdownSeconds,
  }) {
    return PairingState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
      pairingPayload: pairingPayload ?? this.pairingPayload,
      isPaired: isPaired ?? this.isPaired,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        isSuccess,
        errorMessage,
        pairingPayload,
        isPaired,
        countdownSeconds,
      ];
}
