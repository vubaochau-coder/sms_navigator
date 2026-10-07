import 'package:equatable/equatable.dart';

import '../../../core/enums/join_phase.dart';
import '../../../core/models/invite_preview_model.dart';
import '../../../core/models/pairing_session_model.dart';

export '../../../core/enums/join_phase.dart';

class JoinState extends Equatable {
  final JoinPhase phase;
  final InvitePayload? invite;
  final InvitePreviewModel? preview;
  final String deviceName;
  final String? requestId;
  final String? errorMessage;
  final String? errorCode;

  const JoinState({
    this.phase = JoinPhase.initial,
    this.invite,
    this.preview,
    this.deviceName = '',
    this.requestId,
    this.errorMessage,
    this.errorCode,
  });

  bool get isResolving => phase == JoinPhase.resolving;
  bool get isClaiming => phase == JoinPhase.claiming;
  bool get isReady => phase == JoinPhase.ready;
  bool get isSubmitting => isClaiming;
  bool get isAlreadyPending => errorCode == 'REQUEST_ALREADY_PENDING';

  String get channelName => preview?.channelName ?? '';
  String get ownerDeviceName => preview?.ownerDeviceName ?? '';

  JoinState copyWith({
    JoinPhase? phase,
    InvitePayload? invite,
    InvitePreviewModel? preview,
    String? deviceName,
    String? requestId,
    String? errorMessage,
    String? errorCode,
    bool clearError = false,
  }) {
    return JoinState(
      phase: phase ?? this.phase,
      invite: invite ?? this.invite,
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
    invite,
    preview,
    deviceName,
    requestId,
    errorMessage,
    errorCode,
  ];
}
