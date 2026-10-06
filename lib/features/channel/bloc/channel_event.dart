import 'package:equatable/equatable.dart';

abstract class ChannelEvent extends Equatable {
  const ChannelEvent();

  @override
  List<Object?> get props => [];
}

/// Load danh sách kênh khi mở tab / pull-to-refresh (2.1).
class ChannelLoadDataEvent extends ChannelEvent {
  const ChannelLoadDataEvent();
}

/// Tạo kênh (2.2) — xuất hiện ở nhóm "Kênh của bạn".
class ChannelCreated extends ChannelEvent {
  final String name;

  const ChannelCreated(this.name);

  @override
  List<Object?> get props => [name];
}

/// Đổi tên thiết bị (1.2) — server tự fan-out mọi kênh + request chờ duyệt.
class DeviceRenamed extends ChannelEvent {
  final String deviceName;

  const DeviceRenamed(this.deviceName);

  @override
  List<Object?> get props => [deviceName];
}

/// Hủy yêu cầu tham gia kênh đang chờ duyệt.
class ChannelPendingJoinCancelled extends ChannelEvent {
  final String requestId;
  final String? successMessage;
  final String? errorMessage;

  const ChannelPendingJoinCancelled(
    this.requestId, {
    this.successMessage,
    this.errorMessage,
  });

  @override
  List<Object?> get props => [requestId, successMessage, errorMessage];
}
