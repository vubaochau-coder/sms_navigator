import 'package:equatable/equatable.dart';

import '../../../core/models/pairing_request_model.dart';

abstract class ChannelDetailEvent extends Equatable {
  const ChannelDetailEvent();

  @override
  List<Object?> get props => [];
}

/// Mở màn chi tiết / refresh khi mở app (4.1).
class ChannelDetailLoaded extends ChannelDetailEvent {
  final String channelId;

  const ChannelDetailLoaded(this.channelId);

  @override
  List<Object?> get props => [channelId];
}

/// Approve member (4.2) — dialog xác nhận rồi mới gọi; bên trong tự rotate.
class ChannelDetailConfirmed extends ChannelDetailEvent {
  final PairingRequestModel request;

  const ChannelDetailConfirmed(this.request);

  @override
  List<Object?> get props => [request];
}

/// Reject request (4.3) — dialog xác nhận màu đỏ; mã QR đã cháy.
class ChannelDetailRejected extends ChannelDetailEvent {
  final PairingRequestModel request;

  const ChannelDetailRejected(this.request);

  @override
  List<Object?> get props => [request];
}

/// Revoke member (4.4) — dialog cảnh báo mức cao; tự rotate key.
class ChannelDetailMemberRevoked extends ChannelDetailEvent {
  final String deviceId;

  const ChannelDetailMemberRevoked(this.deviceId);

  @override
  List<Object?> get props => [deviceId];
}

// Backward-compatibility aliases
typedef ApprovalEvent = ChannelDetailEvent;
typedef ApprovalLoaded = ChannelDetailLoaded;
typedef ApprovalConfirmed = ChannelDetailConfirmed;
typedef ApprovalRejected = ChannelDetailRejected;
typedef ApprovalMemberRevoked = ChannelDetailMemberRevoked;
