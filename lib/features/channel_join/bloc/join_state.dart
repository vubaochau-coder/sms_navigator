import 'package:equatable/equatable.dart';

import '../../../core/enums/join_phase.dart';
import '../../../core/models/invite_preview_model.dart';

export '../../../core/enums/join_phase.dart';

class JoinState extends Equatable {
  final JoinPhase phase;

  /// Opaque QR code (v3.3) — claim gửi `code`.
  final String? code;
  final InvitePreviewModel? preview;
  final String deviceName;
  final String? requestId;
  final String? errorMessage;
  final String? errorCode;

  const JoinState({
    this.phase = JoinPhase.initial,
    this.code,
    this.preview,
    this.deviceName = '',
    this.requestId,
    this.errorMessage,
    this.errorCode,
  });

  bool get isClaiming => phase == JoinPhase.claiming;
  bool get isReady => phase == JoinPhase.ready;
  bool get isSubmitting => isClaiming;
  bool get isAlreadyPending => errorCode == 'REQUEST_ALREADY_PENDING';

  String get channelName => preview?.channelName ?? '';
  String get ownerDeviceName => preview?.ownerDeviceName ?? '';

  JoinState copyWith({
    JoinPhase? phase,
    String? code,
    InvitePreviewModel? preview,
    String? deviceName,
    String? requestId,
    String? errorMessage,
    String? errorCode,
    bool clearError = false,
  }) {
    return JoinState(
      phase: phase ?? this.phase,
      code: code ?? this.code,
      preview: preview ?? this.preview,
      deviceName: deviceName ?? this.deviceName,
      requestId: requestId ?? this.requestId,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
    );
  }

  @override
  List<Object?> get props => [
    phase,
    code,
    preview,
    deviceName,
    requestId,
    errorMessage,
    errorCode,
  ];
}
