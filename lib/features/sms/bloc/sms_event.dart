import 'package:equatable/equatable.dart';

import '../../../core/models/channel_event.dart';

abstract class SmsEvent extends Equatable {
  const SmsEvent();

  @override
  List<Object?> get props => [];
}

/// User chọn ngày trên calendar (6.1).
/// Nghiệp vụ: BLoC sẽ kiểm tra date có khác không, emit selectedDate mới và tự add [SmsLoadDataEvent].
class SmsDateSelected extends SmsEvent {
  final DateTime date;

  const SmsDateSelected(this.date);

  @override
  List<Object?> get props => [date];
}

/// Event thuần túy chịu trách nhiệm load dữ liệu SMS theo trạng thái state hiện tại.
/// Áp dụng bloc concurrency (restartable) và hỗ trợ CancelToken để hủy request cũ.
///
/// [silent] = làm mới ngầm (tin mới qua FCM, app quay lại foreground): không
/// hiện shimmer, lỗi không bắn toast — danh sách cũ vẫn giữ nguyên.
class SmsLoadDataEvent extends SmsEvent {
  final bool silent;

  const SmsLoadDataEvent({this.silent = false});

  @override
  List<Object?> get props => [silent];
}

/// Sự kiện kênh (FCM / chạm thông báo) có thể làm thay đổi danh sách tin (1.3).
class SmsChannelEventReceived extends SmsEvent {
  final ChannelEvent event;

  const SmsChannelEventReceived(this.event);

  @override
  List<Object?> get props => [event];
}

/// App quay lại foreground — tin có thể đã đến khi app ở nền (1.3).
class SmsAppResumed extends SmsEvent {
  const SmsAppResumed();
}
