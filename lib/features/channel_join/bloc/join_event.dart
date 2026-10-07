import 'package:equatable/equatable.dart';

import '../../../core/models/pairing_session_model.dart';

abstract class JoinEvent extends Equatable {
  const JoinEvent();

  @override
  List<Object?> get props => [];
}

/// Bắt đầu resolve session từ mã mời đã quét.
class JoinResolveStarted extends JoinEvent {
  final InvitePayload invite;

  const JoinResolveStarted(this.invite);

  @override
  List<Object?> get props => [invite];
}


/// Bấm [Gửi yêu cầu kết nối] — claim QR với tên thiết bị hiện tại (read-only).
class JoinSubmitted extends JoinEvent {
  final String deviceName;

  const JoinSubmitted(this.deviceName);

  @override
  List<Object?> get props => [deviceName];
}
