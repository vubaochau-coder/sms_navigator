import 'package:equatable/equatable.dart';

import '../../../core/models/pairing_session_model.dart';

abstract class JoinEvent extends Equatable {
  const JoinEvent();

  @override
  List<Object?> get props => [];
}

/// Sau khi quét QR / mở deeplink: hiển thị dialog xác nhận (3.2).
class JoinInviteScanned extends JoinEvent {
  final InvitePayload invite;

  const JoinInviteScanned(this.invite);

  @override
  List<Object?> get props => [invite];
}

/// Bấm [Gửi yêu cầu kết nối] (3.3) — lúc này mới claim QR.
class JoinSubmitted extends JoinEvent {
  final String deviceName;

  const JoinSubmitted(this.deviceName);

  @override
  List<Object?> get props => [deviceName];
}

/// Hủy request (3.5) — chỉ khi còn PENDING.
class JoinCancelled extends JoinEvent {
  const JoinCancelled();
}

/// Refresh trạng thái các request của tôi (reconcile khi mở app, SRD 7.3).
class JoinRequestsRefreshed extends JoinEvent {
  const JoinRequestsRefreshed();
}
