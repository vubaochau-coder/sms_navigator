import 'package:equatable/equatable.dart';

abstract class ChannelInviteEvent extends Equatable {
  const ChannelInviteEvent();

  @override
  List<Object?> get props => [];
}

/// Khởi tạo phiên mời khi mở BottomSheet (nếu chưa có session hoặc session đã hết hạn).
class ChannelInviteStarted extends ChannelInviteEvent {
  const ChannelInviteStarted();
}

/// Tạo lại hoặc làm mới mã QR mời tham gia kênh.
class ChannelInviteRegenerated extends ChannelInviteEvent {
  const ChannelInviteRegenerated();
}
