import 'package:equatable/equatable.dart';

import '../../../core/enums/join_phase.dart';
import '../../../core/models/pairing_request_model.dart';
import '../../../core/models/pairing_session_model.dart';

export '../../../core/enums/join_phase.dart';

class JoinState extends Equatable {
  final JoinPhase phase;
  final InvitePayload? invite;
  final String channelName;
  final String ownerDeviceName;
  final String deviceName;
  final String? requestId;
  final List<PairingRequestModel> myRequests;
  final bool isSubmitting;
  final String? errorMessage;

  const JoinState({
    this.phase = JoinPhase.waitingApproval,
    this.invite,
    this.channelName = '',
    this.ownerDeviceName = '',
    this.deviceName = '',
    this.requestId,
    this.myRequests = const [],
    this.isSubmitting = false,
    this.errorMessage,
  });

  JoinState copyWith({
    JoinPhase? phase,
    InvitePayload? invite,
    String? channelName,
    String? ownerDeviceName,
    String? deviceName,
    String? requestId,
    List<PairingRequestModel>? myRequests,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
  }) {
    return JoinState(
      phase: phase ?? this.phase,
      invite: invite ?? this.invite,
      channelName: channelName ?? this.channelName,
      ownerDeviceName: ownerDeviceName ?? this.ownerDeviceName,
      deviceName: deviceName ?? this.deviceName,
      requestId: requestId ?? this.requestId,
      myRequests: myRequests ?? this.myRequests,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    phase,
    invite,
    channelName,
    ownerDeviceName,
    deviceName,
    requestId,
    myRequests,
    isSubmitting,
    errorMessage,
  ];
}
