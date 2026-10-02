import 'package:equatable/equatable.dart';
import '../../data/models/pairing_payload_model.dart';

/// Kết quả lần xuất ảnh QR gần nhất — UI ánh xạ sang chuỗi l10n khi toast.
enum QrExportStatus { success, genericFailure, permissionDenied, noQr }

class PairingState extends Equatable {
  static const int defaultCountdownSeconds = 600;

  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final PairingPayloadModel? pairingPayload;
  final bool isPaired;

  /// Máy A: Máy B đã quét mã, confirm và shared secret đã được derive —
  /// relay đã sẵn sàng gửi OTP.
  final bool isReceiverLinked;

  final int countdownSeconds;
  final bool isExportingQr;
  final QrExportStatus? qrExportStatus;
  final int qrExportToken;

  const PairingState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
    this.pairingPayload,
    this.isPaired = false,
    this.isReceiverLinked = false,
    this.countdownSeconds = defaultCountdownSeconds,
    this.isExportingQr = false,
    this.qrExportStatus,
    this.qrExportToken = 0,
  });

  PairingState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    PairingPayloadModel? pairingPayload,
    bool? isPaired,
    bool? isReceiverLinked,
    int? countdownSeconds,
    bool? isExportingQr,
    QrExportStatus? qrExportStatus,
    int? qrExportToken,
  }) {
    return PairingState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
      pairingPayload: pairingPayload ?? this.pairingPayload,
      isPaired: isPaired ?? this.isPaired,
      isReceiverLinked: isReceiverLinked ?? this.isReceiverLinked,
      countdownSeconds: countdownSeconds ?? this.countdownSeconds,
      isExportingQr: isExportingQr ?? this.isExportingQr,
      qrExportStatus: qrExportStatus,
      qrExportToken: qrExportToken ?? this.qrExportToken,
    );
  }

  @override
  List<Object?> get props => [
    isLoading,
    isSuccess,
    errorMessage,
    pairingPayload,
    isPaired,
    isReceiverLinked,
    countdownSeconds,
    isExportingQr,
    qrExportStatus,
    qrExportToken,
  ];
}
